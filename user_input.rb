# This file provides methods for getting + cleaning user input

def gets_string(prompt, min_len=0, max_len=10000000000)

    puts prompt

    valid = false
    str = ''

    while !valid
        str = STDIN.gets.chomp
        if str.length >= min_len && str.length <= max_len
            valid = true
        else
            puts "Incorrect length, try again"
        end
    end

    return str
end


def gets_bool?(prompt)

    puts prompt

    valid = false

    while !valid
        input = STDIN.gets.chomp

        if input == "Y" || input == "YES"
            return true
        elsif input == "N" || input == "NO"
            return false
        end

        puts "Invalid input! Must be a 'yes' or a 'no'"
    end

end