function tt --description "Run test command multiple times and report statistics"
    set -l iterations 10
    set -l test_command ""
    
    # Create log directory in current working directory
    set -l log_dir (pwd)/log
    set -l timestamp (date +"%Y%m%d_%H%M%S")
    set -l log_file "$log_dir/tt_$timestamp.log"
    
    # Create log directory if it doesn't exist
    if not test -d $log_dir
        mkdir -p $log_dir
    end
    
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
    echo "Log file: $log_file"
    echo "=================="
    
    # Also write header to log file
    echo "Test run at: "(date) >> $log_file
    echo "Running test command: $test_command" >> $log_file
    echo "Iterations: $iterations" >> $log_file
    echo "==================" >> $log_file
    
    set -l run_times
    set -l success_count 0
    set -l failure_count 0
    set -l total_time 0
    
    for i in (seq 1 $iterations)
        echo -n "Run $i: "
        
        set -l start_time (date +%s)
        
        # Run the command and capture output and exit status
        set -l output_file (mktemp)
        eval $test_command >$output_file 2>&1
        set -l exit_status $status
        
        # Save output to log file
        echo "" >> $log_file
        echo "=== Run $i Output ===" >> $log_file
        cat $output_file >> $log_file
        rm -f $output_file
        
        set -l end_time (date +%s)
        set -l run_time (math $end_time - $start_time)
        set run_times $run_times $run_time
        set total_time (math $total_time + $run_time)
        
        if test $exit_status -eq 0
            set success_count (math $success_count + 1)
            echo "PASS ($run_time s)"
            echo "Run $i: PASS ($run_time s)" >> $log_file
        else
            set failure_count (math $failure_count + 1)
            echo "FAIL ($run_time s) - exit code: $exit_status"
            echo "Test failed on run $i"
            echo "Run $i: FAIL ($run_time s) - exit code: $exit_status" >> $log_file
            echo "Test failed on run $i" >> $log_file
            break
        end
    end
    
    echo "=================="
    echo "STATISTICS REPORT"
    echo "=================="
    echo "Total runs: "(math $success_count + $failure_count)
    echo "Successful: $success_count"
    echo "Failed: $failure_count"
    
    # Also write statistics to log file
    echo "" >> $log_file
    echo "==================" >> $log_file
    echo "STATISTICS REPORT" >> $log_file
    echo "==================" >> $log_file
    echo "Total runs: "(math $success_count + $failure_count) >> $log_file
    echo "Successful: $success_count" >> $log_file
    echo "Failed: $failure_count" >> $log_file
    
    if test $success_count -gt 0
        set -l avg_time (math $total_time / $success_count)
        echo "Average time: $avg_time s"
        echo "Total time: $total_time s"
        echo "Average time: $avg_time s" >> $log_file
        echo "Total time: $total_time s" >> $log_file
        
        # Calculate min and max times
        set -l min_time $run_times[1]
        set -l max_time $run_times[1]
        
        for time in $run_times
            if test $time -lt $min_time
                set min_time $time
            end
            if test $time -gt $max_time
                set max_time $time
            end
        end
        
        echo "Fastest run: $min_time s"
        echo "Slowest run: $max_time s"
        echo "Fastest run: $min_time s" >> $log_file
        echo "Slowest run: $max_time s" >> $log_file
        
        # Show individual run times
        echo ""
        echo "Individual run times:"
        echo "" >> $log_file
        echo "Individual run times:" >> $log_file
        set -l counter 1
        for time in $run_times
            echo "  Run $counter: $time s"
            echo "  Run $counter: $time s" >> $log_file
            set counter (math $counter + 1)
        end
    end
    
    if test $failure_count -gt 0
        return 1
    else
        return 0
    end
end
