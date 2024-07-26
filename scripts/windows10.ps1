
# ~~# Ejecutar como usuario (no Administrador)
# ~~# Necesario ser Administrador para los SymbolicLinks... recurrimos a gsudo (otra opción podría ser Get-ExecutionPolicy -List etc.)

# https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/09-functions?view=powershell-7.4


function winget_update_install {

    # winget update --All
    # winget upgrade -All

    function all_users {
        winget install `
            brave.brave google.googledrive keepassxcteam.keepassxc insecure.nmap
    }

    function admin_users {
        winget install `
            microsoft.windowsterminal microsoft.powershell devcom.jetbrainsmononerdfont     # jandedobbeleer.ohmyposh
        
        winget install `
            sharkdp.bat eza-community.eza junegunn.fzf git.git gerardog.gsudo `
            gokcehan.lf neovim.neovim burntsushi.ripgrep.gnu tldr-pages.tlrc
        
        tldr --update
        
        winget install microsoft.visualstudiocode `
            -override '/SILENT /mergetasks="addcontextmenufiles,addcontextmenufolders"'
        # winget install microsoft.visualstudiocode -override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
    }

    switch ($env:USERNAME) {
        "pabloqpacin", "operaciones" {
            admin_users
            # break
        }
        default {
            all_users
        }
    }
}

function reload_path {
  $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","MACHINE") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","USER")
}

function setup_dotfiles {

    git clone --depth=1 'https://github.com/pabloqpacin/dotfiles' "$env:HOMEPATH\dotfiles"

    # Terminal
    gsudo New-Item -ItemType SymbolicLink `
        -Target "$env:HOMEPATH\dotfiles\.config\code\User\settings.json" `
        -Path "$env:APPDATA\Code\User\settings.json"

    # VSCode
    Rename-Item `
        -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" `
        -NewName "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.bak"
    gsudo New-Item -ItemType SymbolicLink -Force `
        -Target "$env:HOMEPATH\dotfiles\windows\settings\Terminal\settings.jsonc" `
        -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    # MISC.: bat, lf...
    gsudo New-Item -ItemType SymbolicLink -Target "$env:HOMEPATH\dotfiles\.config\bat" -Path "$env:APPDATA\bat"
    # gsudo New-Item -ItemType SymbolicLink -Target "$env:HOMEPATH\dotfiles\.config\lf" -Path "$env:LOCALAPPDATA\lf"    # UNUSABLE!!

}

function temp_nvim {
    New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\nvim"
    
    gsudo New-Item -ItemType SymbolicLink `
        -Target "$env:HOMEPATH\dotfiles\.vimrc" `
        -Path "$env:LOCALAPPDATA\nvim\init.vim"
}

function setup_nvim {

    git clone 'https://github.com/wbthomason/packer.nvim' "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"

    winget install openjs.nodejs msys2.msys2

    $null = Read-Host "Introduce: 'pacman -Syu --noconfirm base-devel mingw-w64-x86_64-toolchain neofetch'. OK?"
    # TODO: change this to just start it twice
    do {
        Start-Process "C:\msys64\msys2.exe"
        reload_path
        $ask = Read-Host "Run 'msys2' again to complete the installation? (y/N)"
    } while ($ask -eq "y")
    $ask = $null


    gsudo New-Item -ItemType SymbolicLink `
        -Target "$env:HOMEPATH\dotfiles\.config\nvim" `
        -Path "$env:LOCALAPPDATA\nvim"

    $null = Read-Host "Pasa los mensajes de error con <INTRO>, luego escribe :so <INTRO>, :PackerSync <INTRO> y :qa <INTRO>"
    nvim "$env:LOCALAPPDATA\nvim\lua\pabloqpacin\packer.lua"
    $null = Read-Host "Pasa los mensajes de error con <INTRO>, luego escribe :Mason <INTRO> y :qa <INTRO>"
    nvim "$env:LOCALAPPDATA\nvim\after\plugin\lsp.lua"

    # Importante: añadir "$env:SYSTEMDRIVE\msys64\mingw64\bin" al $env:PATH
}


function powershell_profile {

    if (command -v nvim) {

        #     New-Item -ItemType Directory -Path "$env:HOMEPATH\Documents\PowerShell\"

        # $profile_content = @"
        # \$pathsToAdd = @(
        #   "\$env:SYSTEMDRIVE\msys64\mingw64\bin",
        # )

        # foreach (\$path in \$pathsToAdd) {
        #   if (\$env:PATH -notlike "*\$path*") {
        #     \$env:PATH += ";\$path"
        #   }
        # }
        # "@
        #     Set-Content -Value $profile_content -Path "$PROFILE"

    }
}






if ($true) {
    
    winget_update_install
    reload_path
    
    if ("$env:USERNAME" -eq 'pabloqpacin' ) {
        setup_dotfiles
        temp_nvim
        # setup_nvim
    }

    # powershell_profile
}
