# AXON: строка ввода «~/Загрузки ❯» — бирюзовая папка, синяя стрелка (красная, если команда упала).
# Лежит в /etc/fish/functions — выше по приоритету, чем строка ввода из vendor_functions.d.
function fish_prompt
    set -l last_status $status
    set_color 3fd0d0 --bold
    echo -n (prompt_pwd --full-length-dirs 2)
    set_color normal
    echo -n ' '
    if test $last_status -ne 0
        set_color ff5c7a --bold
    else
        set_color 5aa9ff --bold
    end
    echo -n '❯ '
    set_color normal
end
