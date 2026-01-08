function dotcheck --description "Check if all dotfiles tools are installed and working"
    set -l tools \
        fish \
        nvim \
        fzf \
        bat \
        eza \
        rg \
        fd \
        zoxide \
        mise \
        git \
        curl

    # Optional tools (may not be installed on all systems)
    set -l optional_tools \
        direnv \
        jq \
        yq \
        gh \
        kubectx

    set -l missing
    set -l installed
    set -l optional_missing
    set -l optional_installed

    echo "Checking required tools..."
    for tool in $tools
        if command -q $tool
            set -a installed $tool
        else
            set -a missing $tool
        end
    end

    echo "Checking optional tools..."
    for tool in $optional_tools
        if command -q $tool
            set -a optional_installed $tool
        else
            set -a optional_missing $tool
        end
    end

    # Report results
    echo ""
    set_color green
    echo "✓ Installed: "(count $installed)" required tools"
    set_color normal
    for tool in $installed
        echo "  $tool: "($tool --version 2>/dev/null | head -1 || echo "installed")
    end

    if test (count $missing) -gt 0
        echo ""
        set_color red
        echo "✗ Missing: "(count $missing)" required tools"
        set_color normal
        for tool in $missing
            echo "  $tool"
        end
    end

    echo ""
    set_color cyan
    echo "○ Optional installed: "(count $optional_installed)
    set_color normal
    for tool in $optional_installed
        echo "  $tool"
    end

    if test (count $optional_missing) -gt 0
        echo ""
        set_color yellow
        echo "○ Optional not installed: "(count $optional_missing)
        set_color normal
        for tool in $optional_missing
            echo "  $tool"
        end
    end

    # Return error code if required tools are missing
    if test (count $missing) -gt 0
        return 1
    end
end
