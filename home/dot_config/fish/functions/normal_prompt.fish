function normal_prompt --description 'Restore normal prompt for current session'
    # Restore original prompt by reloading from files
    source /Users/naoya-furudono/.config/fish/functions/fish_prompt.fish
    source /Users/naoya-furudono/.config/fish/functions/fish_right_prompt.fish
    
    echo "Restored normal prompt (session only)"
end