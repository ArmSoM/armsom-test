#!/bin/bash
# Supervise one independent two-hour DDR aging item.
set -u
export LC_ALL=C
mode=${1:-}
case "$mode" in 1|2|3|4|5) ;; *) echo 'Usage: aging.sh {1|2|3|4|5}'; exit 1;; esac
duration=7200
outcome=FAIL
reason='Unexpected termination'
start=0
elapsed=0
mem_pid=0
stress_pid=0
mem_loops=0
stress_done=0
count=0
old_governor=''
old_freq=''
use_mem=0; use_stress=0; use_scale=0
case "$mode" in 1) use_mem=1;; 2) use_stress=1;; 3) use_scale=1;; 4) use_mem=1; use_stress=1;; 5) use_mem=1; use_stress=1; use_scale=1;; esac
fail() { reason="$*"; outcome=FAIL; echo "ERROR: $reason"; exit 1; }
clock_now() { local uptime rest; read -r uptime rest < /proc/uptime; now=${uptime%.*}; }
[[ $EUID == 0 ]] || fail 'Run as root (sudo -n must be permitted).'
command -v flock >/dev/null || fail 'flock is missing'
exec 9>/run/armsom-ddr-aging.lock
flock -n 9 || fail 'Another DDR aging test is already running.'
(( !use_mem )) || command -v memtester >/dev/null || fail 'memtester is missing'
(( !use_stress )) || command -v stressapptest >/dev/null || fail 'stressapptest is missing'
dmc=/sys/class/devfreq/dmc
if (( use_scale )); then
    [[ -r $dmc/governor && -w $dmc/governor && -r $dmc/available_frequencies ]] || fail 'DDR devfreq interface is unavailable'
    old_governor=$(cat "$dmc/governor")
    old_freq=$(cat "$dmc/cur_freq")
    read -ra freqs < "$dmc/available_frequencies"
    (( ${#freqs[@]} )) || fail 'No DDR frequencies available'
    for freq in "${freqs[@]}"; do [[ $freq =~ ^[0-9]+$ ]] || fail 'Invalid DDR frequency'; done
fi
log_dir=/data/rockchip-test/aging/$(date +%Y%m%d-%H%M%S)-$$-mode$mode
mkdir -p "$log_dir" || fail 'Cannot create log directory'
declare -A offsets=() seen=()
last_source=''
flush_logs() {
    local name size bytes
    for name in memtester stressapptest ddr-scaling; do
        [[ -v offsets[$name] ]] || continue
        size=$(stat -c %s "$log_dir/$name.log" 2>/dev/null) || continue
        bytes=$((size-offsets[$name]))
        if (( bytes > 0 )); then
            if (( use_mem+use_stress+use_scale > 1 )) && [[ $last_source != "$name" ]]; then
                printf '\n--- %s ---\n' "$name"
                last_source=$name
            fi
            # Read exactly this snapshot; later writes are streamed next time.
            dd if="$log_dir/$name.log" iflag=skip_bytes,count_bytes skip="${offsets[$name]}" count="$bytes" status=none
            offsets[$name]=$size
        fi
    done
}
stop_worker() {
    local pid=$1 i
    (( pid > 0 )) || return 0
    kill -TERM "$pid" 2>/dev/null || true
    for i in {1..20}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
    done
    kill -KILL "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
}
mem_errors() {
    grep -Eiq 'FAILURE:|FAIL:|Status:[[:space:]]*FAIL|had found [1-9][0-9]* failures|failed|ERROR:' "$log_dir/memtester.log"
}
cleanup() {
    local code=$? restored
    trap - EXIT INT TERM HUP
    stop_worker "$mem_pid"
    stop_worker "$stress_pid"
    if (( use_mem )) && [[ -f $log_dir/memtester.log ]] && mem_errors; then
        outcome=FAIL; reason='memtester reported an error'; code=1
    fi
    if (( use_scale )); then
        if [[ $old_governor == userspace ]]; then
            if ! echo "$old_freq" > "$dmc/userspace/set_freq"; then code=1; outcome=FAIL; reason='Cannot restore DDR frequency'; fi
        fi
        if ! echo "$old_governor" > "$dmc/governor"; then code=1; outcome=FAIL; reason='Cannot restore DDR governor'; fi
        restored=$(cat "$dmc/governor")
        echo "DDR governor restored: $restored (original: $old_governor)"
        if [[ $restored != "$old_governor" ]]; then code=1; outcome=FAIL; reason='DDR governor restore verification failed'; fi
        if [[ $old_governor == userspace && $(cat "$dmc/cur_freq") != "$old_freq" ]]; then
            code=1; outcome=FAIL; reason='DDR frequency restore verification failed'
        fi
    fi
    flush_logs
    clock_now
    (( start == 0 )) || elapsed=$((now-start))
    if (( code != 0 )) && [[ $outcome == PASS ]]; then outcome=FAIL; fi
    echo
    echo "Result: $outcome; reason=$reason; completed_memtester_loops=$mem_loops; verified_frequency_changes=$count"
    echo "Logs: $log_dir"
    echo "ARMSOM_AGING_RESULT mode=$mode status=$outcome duration=$duration elapsed=$elapsed"
    case "$outcome" in PASS) exit 0;; STOPPED) exit 130;; *) exit 1;; esac
}
trap cleanup EXIT
trap 'outcome=STOPPED; reason="Stopped by signal before completion"; exit 130' INT TERM HUP
workers=$((use_mem+use_stress))
if (( workers )); then
    available=$(awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo)
    # Keep half of available RAM for the system and share the other half.
    memory=$((available/2/workers-10))
    (( memory >= 32 )) || fail 'Not enough available memory'
    echo "Memory: available=${available}MB, per worker=${memory}MB, workers=$workers"
fi
prefix=()
if command -v stdbuf >/dev/null; then prefix=(stdbuf -oL -eL); fi
launch_mem() {
    echo "CMD: memtester -e 1 ${memory}M 1 (full loop $((mem_loops+1)))"
    "${prefix[@]}" memtester -e 1 "${memory}M" 1 >> "$log_dir/memtester.log" 2>&1 &
    mem_pid=$!
}
echo "DDR aging mode=$mode; required duration=$duration seconds (2 hours)"
echo "Logs: $log_dir"
if (( use_scale )); then
    echo userspace > "$dmc/governor" || fail 'Cannot select userspace governor'
    [[ -w $dmc/userspace/set_freq ]] || fail 'DDR userspace frequency interface is unavailable'
    offsets[ddr-scaling]=0
fi
clock_now; start=$now
if (( use_mem )); then offsets[memtester]=0; launch_mem; fi
if (( use_stress )); then
    offsets[stressapptest]=0
    echo "CMD: stressapptest -s $duration -i 4 -C 4 -W --stop_on_errors -M $memory -l $log_dir/stressapptest-detail.log"
    "${prefix[@]}" stressapptest -s "$duration" -i 4 -C 4 -W --stop_on_errors -M "$memory" -l "$log_dir/stressapptest-detail.log" > "$log_dir/stressapptest.log" 2>&1 &
    stress_pid=$!
fi
while :; do
    clock_now; elapsed=$((now-start))
    if (( mem_pid > 0 )) && ! kill -0 "$mem_pid" 2>/dev/null; then
        code=0; wait "$mem_pid" || code=$?; mem_pid=0
        (( code == 0 )) || fail "memtester exited with status $code"
        mem_errors && fail 'memtester reported an error'
        passes=$(grep -Ec 'Status:[[:space:]]*PASS' "$log_dir/memtester.log" || true)
        zeroes=$(grep -Ec 'had found 0 failures' "$log_dir/memtester.log" || true)
        (( passes > mem_loops && zeroes > mem_loops )) || fail 'memtester did not report a complete error-free loop'
        ((mem_loops+=1))
        echo "memtester complete loops: $mem_loops (PASS)"
        (( elapsed >= duration )) || launch_mem
    fi
    if (( stress_pid > 0 )) && ! kill -0 "$stress_pid" 2>/dev/null; then
        code=0; wait "$stress_pid" || code=$?; stress_pid=0
        (( code == 0 )) || fail "stressapptest exited with status $code"
        (( elapsed >= duration )) || fail 'stressapptest exited before the required duration'
        grep -Eq 'Status:[[:space:]]*PASS' "$log_dir/stressapptest.log" || fail 'stressapptest did not report PASS'
        grep -Eq 'with 0 hardware incidents, 0 errors' "$log_dir/stressapptest.log" || fail 'stressapptest did not report zero errors and hardware incidents'
        stress_done=1
        echo 'stressapptest: two-hour run completed, PASS, zero hardware incidents and errors'
    fi
    if (( elapsed >= duration )); then
        if (( mem_pid > 0 )); then stop_worker "$mem_pid"; mem_pid=0; fi
        if (( use_mem )); then
            mem_errors && fail 'memtester reported an error'
            passes=$(grep -Ec 'Status:[[:space:]]*PASS' "$log_dir/memtester.log" || true)
            zeroes=$(grep -Ec 'had found 0 failures' "$log_dir/memtester.log" || true)
            (( passes > 0 && zeroes > 0 )) || fail 'No complete error-free memtester loop within the required duration'
            mem_loops=$passes
        fi
        if (( use_scale )); then
            (( ${#seen[@]} == ${#freqs[@]} )) || fail 'Not all available DDR frequencies were verified'
        fi
        if (( !use_stress || stress_done )); then
            outcome=PASS; reason='Required duration and all checks satisfied'; exit 0
        fi
        (( elapsed < duration+30 )) || fail 'stressapptest did not finish normally within the cleanup allowance'
    elif (( use_scale )); then
        # Visit every available frequency, then repeat; no frequency is skipped.
        freq=${freqs[count % ${#freqs[@]}]}
        echo "$freq" > "$dmc/userspace/set_freq" || fail 'DDR frequency write failed'
        current=$(cat "$dmc/cur_freq")
        if [[ $current != "$freq" ]]; then
            echo "ddr freq: failed change to $freq HZ, now $current Hz" >> "$log_dir/ddr-scaling.log"
            fail 'DDR frequency verification failed'
        fi
        printf 'cnt: %s, ddr freq: success change to %s Hz\n' "$count" "$current" >> "$log_dir/ddr-scaling.log"
        seen[$freq]=1
        ((count+=1))
    fi
    flush_logs
    command=''
    if IFS= read -r -t 1 command; then
        if [[ $command == stop ]]; then outcome=STOPPED; reason='Stopped by user before completion'; exit 130; fi
    else
        code=$?
        if (( code == 1 )); then outcome=STOPPED; reason='Controller closed input before completion'; exit 130; fi
    fi
done
