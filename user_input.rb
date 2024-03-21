# This file provides methods for getting + cleaning user input

def gets_string(prompt, min_len=0, max_len=10000000000)

    puts prompt

    valid = false
    str = ''

    while !valid
        str = gets.chomp
        if str.length >= min_len && str.length <= max_len
            valid = true
        else
            puts "Incorrect length, try again"
        end
    end

    return str
end