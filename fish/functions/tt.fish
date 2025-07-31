function tt --description "Run test command multiple times and report statistics"
    set -l iterations 10
    set -l test_command ""
    
    # Parse arguments
    if test (count $argv) -eq 0
        echo "Usage: tt <test_command> [iterations]"
        echo "  test_command: Command to run for testing"
        echo "  iterations: Number of times to run (default: 10)"
        return 1
    end
    
    # Get test command (all arguments except last one if it's a number)
    if test (count $argv) -gt 1; and string match -qr '^\d+$' $argv[-1]
        set iterations $argv[-1]
        set test_command $argv[1..-2]
    else
        set test_command $argv
    end
    
    echo "Running test command: $test_command"
    echo "Iterations: $iterations"
    echo "=================="
    
    set -l run_times
    set -l success_count 0
    set -l failure_count 0
    set -l total_time 0
    
    for i in (seq 1 $iterations)
        echo -n "Run $i: "
        
        set -l start_time (date +%s.%3N)
        
        # Run the command and capture exit status
        eval $test_command >/dev/null 2>&1
        set -l exit_status $status
        
        set -l end_time (date +%s.%3N)
        set -l run_time (math "$end_time - $start_time")
        set run_times $run_times $run_time
        set total_time (math "$total_time + $run_time")
        
        if test $exit_status -eq 0
            set success_count (math "$success_count + 1")
            echo "PASS ({$run_time}s)"
        else
            set failure_count (math "$failure_count + 1")
            echo "FAIL ({$run_time}s) - exit code: $exit_status"
            echo "Test failed on run $i"
            break
        end
    end
    
    echo "=================="
    echo "STATISTICS REPORT"
    echo "=================="
    echo "Total runs: "(math "$success_count + $failure_count")
    echo "Successful: $success_count"
    echo "Failed: $failure_count"
    
    if test $success_count -gt 0
        set -l avg_time (math "$total_time / $success_count")
        echo "Average time: {$avg_time}s"
        echo "Total time: {$total_time}s"
        
        # Calculate min and max times
        set -l min_time $run_times[1]
        set -l max_time $run_times[1]
        
        for time in $run_times
            if test (math "$time < $min_time") -eq 1
                set min_time $time
            end
            if test (math "$time > $max_time") -eq 1
                set max_time $time
            end
        end
        
        echo "Fastest run: {$min_time}s"
        echo "Slowest run: {$max_time}s"
        
        # Show individual run times
        echo ""
        echo "Individual run times:"
        for i in (seq 1 (count $run_times))
            echo "  Run $i: {$run_times[$i]}s"
        end
    end
    
    if test $failure_count -gt 0
        return 1
    else
        return 0
    end
end
