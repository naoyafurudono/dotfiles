function simple_prompt --description 'Switch to simple prompt for current session'
    function fish_prompt
        echo -n '$ '
    end
    
    function fish_right_prompt
        # Empty right prompt
    end
    
    echo "Switched to simple prompt (session only)"
end
