#!/usr/bin/perl -w

# author: Xinhong Yang
# zID: z5098300
# should examine the code from line798, lines from 7 to 796 are functions

# function for dealing the sed command when there is a 'q' char in the command end
# different dealing method depends on the format of prefix
# 1: the prefix is just a number -> example 'sed 1q'
# 2: the prefix is just a regex -> example 'sed /2/q'
# 3: the command is '$q'
# 4: the command length is 1 -> example 'q';
# $flag = 0 -> no '-n' flag -> print as required
# $flag = 1 -> has '-n' flag -> print nothing
sub qcommand {
    my ($argLen, $commandArgument, $flag) = @_;
    # case: 3q
    # if the first char is a 'number', $flag = 0 indicate no '-n' flag
    # no '-n' flag -> print line until reach p lines
    if ($argLen != 1 && $commandArgument =~ /^(\d+)[qpd]$/) {
        $terminateNum = $1;
        if ($terminateNum == 0) {
            print "speed: command line: invalid command\n";
            exit;
        }
        $i = 0;
        while ($line = <STDIN>) {
            if ($i == $terminateNum) {
                last;
            }
            if ($flag == 0) {
                print "$line";
            }
            $i++;
        }
    # case: /2/q
    # if the first char is '/' deliminter
    # no '-n' flag -> print line until line match regex
    } elsif ($argLen != 1 && $commandArgument =~ /^\/(.+)\/[qpd]$/) {
        $regex = $1;
        while ($line = <STDIN>) {
            if ($flag == 0) {
                print "$line";
            }
            chomp $line;
            if ($line =~ /$regex/) {
                last;
            }
        }
    # case: $q
    # no '-n' flag -> print line
    } elsif ($commandArgument eq "\$q") {
        while ($line = <STDIN>) {
            if ($flag == 0) {
                print "$line";
            }
        }
    # case: q
    # if the argument is only 'q' itself, print the first line if there is a first line
    } elsif ($argLen == 1) {
        while ($line = <STDIN>) {
            if ($flag == 0) {
                print "$line";
            }
            last;
        }
    # other case, print error
    } else {
        print "speed: command line: invalid command\n";
        exit;
    }
}

# function for dealing the sed command when there is a 'd' char in the command end
# different dealing method depends on the format of prefix
# 1: the prefix is just a number -> example 'sed 1d'
# 2: the prefix is just a regex -> example 'sed /2/d'
# 3: the command is '$d'
# 4: the command length is 1 -> example 'd';
# 5: the command has start line and end line -> example 3,5d
# 6: the command has regex end line -> example 3, /2/d
# 7: the command has regex start line -> example /2/, 4d
# 8: the command has regex start line and end line -> example /2/,/4/d
# $flag = 0 -> no '-n' flag -> print as required
# $flag = 1 -> has '-n' flag -> print nothing
sub dcommand {
    my ($argLen, $commandArgument, $flag) = @_;

    # case: 1d
    # no '-n' flag -> print line other than the d line
    # the number can not be zero
    if ($argLen != 1 && $commandArgument =~ /^(\d+)d$/) {
        $terminateNum = $1;
        if ($terminateNum == 0) {
            print "speed: command line: invalid command\n";
            exit;
        }
        $i = 0;
        while ($line = <STDIN>) {
            if ($i != $terminateNum-1) {
                if ($flag == 0) {
                    print "$line";
                }
            }
            $i++;
        }
    # case: /2/d
    # no '-n' flag -> print line other than the match line
    } elsif ($argLen != 1 && $commandArgument =~ /^\/([^\/]+)\/d$/) {
        $regex = $1;
        while ($line = <STDIN>) {
            chomp $line;
            if ($line !~ /$regex/) {
                if ($flag == 0) {
                    print "$line\n";
                }
            }
        }
    # case: $d
    # no '-n' flag -> print line
    } elsif ($commandArgument eq "\$d"){
        @array = <STDIN>;
        $length = @array;
        for ($i = 0; $i < $length-1; $i++) {
            if ($flag == 0) {
                print "$array[$i]";
            }
        }
    # case: 3,5d
    # print the line if the line is not in the range of start numebr and end number
    # if start number is bigger than end number, don't print the start number
    } elsif ($commandArgument =~ /^(\d),(\d)d$/) {
        $startNum = $1-1;
        $endNum = $2-1;
        @array = <STDIN>;
        if ($startNum >= $endNum) {
            for ($i = 0; $i < @array; $i++) {
                if ($i != $startNum) {
                    if ($flag == 0) {
                        print "$array[$i]";
                    }
                }
            }
        } else {
            for ($i = 0; $i < @array; $i++) {
                if ($i < $startNum || $i > $endNum) {
                    if ($flag == 0) {
                        print "$array[$i]";
                    }
                }
            }
        }
    # case: 3,/2/d
    # TODO: add the condition when the regex is empty (don't have time to do)
    # don't print the line if the line is bigger than the start number and there is no match end line found
    # other situation, print the line
    } elsif ($commandArgument =~ /^(\d),\/(.*)\/d$/) {
        $startNum = $1-1;
        $regex = $2;
        @array = <STDIN>;
        $cond = 0;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;
            if ($flag == 0) {
                if (($i < $startNum) || ($i > $startNum && $cond == 1)) {
                    print "$array[$i]";
                }
            }
            if ($i > $startNum && $line =~ /$regex/) {
                $cond = 1;
            }
        }
    # case: /2/,5d
    # print the line when the line number didnot match the regex and there is no match history
    # print the line that is bigger than the end number and didnot match the regex
    } elsif ($commandArgument =~ /^\/(.+)\/,(\d)d$/){
        $regex = $1;
        $endNum = $2;
        @array = <STDIN>;
        $previousMatch = 0;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;
            if ($line =~ /$regex/) {
                $previousMatch = 1;
            }
            if ($flag == 0 ) {
                if ($previousMatch == 0) {
                    print "$array[$i]";
                } elsif ($i >= $endNum && $line !~ /$regex/) {
                    print "$array[$i]";
                }
            }
        }
    # case: /2/,/5/d
    # bascially combine the logic thinking of the previous case, (there is no particular start line and endline)
    # print the line if line didnot match and no previous match history
    # turn previous match on when there is a match and previous match is 0
    # turn previous match off when there is a match and previous match is 1
    } elsif ($commandArgument =~ /^\/(.+)\/,\/(.+)\/d$/) {
        $regex = $1;
        $regextwo = $2;

        $previousMatch = 0;
        @array = <STDIN>;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;

            if ($line !~ /$regex/ && $previousMatch == 0) {
                if ($flag == 0) {
                    print "$line\n";
                }
            } elsif ($line =~ /$regex/ && $previousMatch == 0) {
                $previousMatch = 1;
            } elsif ($line =~ /$regextwo/ && $previousMatch == 1) {
                $previousMatch = 0;
            }
        }
    # othercase, error
    } elsif ($argLen != 1) {
        print "speed: command line: invalid command\n";
        exit;
    }
}

# function for dealing the sed command when there is a 'p' char in the command end
# different dealing method depends on the format of prefix
# 1: the prefix is just a number -> example 'sed 1p'
# 2: the prefix is just a regex -> example 'sed /2/p'
# 3: the command is '$p'
# 4: the command length is 1 -> example 'p';
# 5: the command has start line and end line -> example 3,5p
# 6: the command has regex end line -> example 3, /2/p
# 7: the command has regex start line -> example /2/, 4p
# 8: the command has regex start line and end line -> example /2/,/4/p
# $flag = 0 -> no '-n' flag -> print other line (include the match line)
# $flag = 1 -> has '-n' flag -> print that match line 
sub pcommand {
    my ($argLen, $commandArgument, $flag) = @_;

    # case: 1p
    # print the line that match the line number
    # print other line if flag is no given
    if ($argLen != 1 && $commandArgument =~ /^(\d+)p$/) {
        $terminateNum = $1;
        if ($terminateNum == 0) {
            print "speed: command line: invalid command\n";
            exit;
        }
        $i = 0;
        while ($line = <STDIN>) {
            if ($flag == 0) {
                print "$line";
            }
            if ($i == $terminateNum - 1) {
                print "$line";
            }
            $i++;
        }
    # case: /2/p
    # print the line that match the regex
    # print other line if flag is no given
    } elsif ($argLen != 1 && $commandArgument =~ /^\/([^\/]+)\/p$/) {
        $regex = $1;
        while ($line = <STDIN>) {
            if ($flag == 0) {
                print "$line";
            }
            chomp $line;
            if ($line =~ /$regex/) {
                print "$line\n";
            } 
        }
    # case: $p
    # print the line that 
    # print other line if flag is no given
    } elsif ($commandArgument eq "\$p") {
        @array = <STDIN>;
        $length = @array;
        for ($i = 0; $i < $length; $i++) {
            if ($flag == 0) {
                print "$array[$i]";
            }
            if ($i == $length-1) {
                print "$array[$length-1]";
            }
        }
    # case: 3,5p
    # print the line that start from begin and end
    # print other line if flag is no given
    } elsif ($commandArgument =~ /^(\d),(\d)p$/) {
        $startNum = $1-1;
        $endNum = $2-1;
        @array = <STDIN>;
        if ($startNum >= $endNum) {
            for ($i = 0; $i < @array; $i++) {
                if ($flag == 0) {
                    print "$array[$i]";
                }
                if ($i == $startNum) {
                    print "$array[$startNum]";
                }
            }
        } else {
            for ($i = 0; $i < @array; $i++) {
                if ($flag == 0) {
                    print "$array[$i]";
                }
                if ($i >= $startNum && $i <= $endNum) {
                    print "$array[$i]";
                }
            }  
        }
    # case: 3,/5/p
    # TODO: add the condition when the regex is empty (not yet implemented, don't have time)
    # print the line that start from begin and end that match the regex
    # print other line if flag is no given
    } elsif ($commandArgument =~ /^(\d),\/(.*)\/p$/) {
        $startNum = $1-1;
        $regex = $2;
        @array = <STDIN>;
        $cond = 0;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;
            if ($flag == 0) {
                print "$array[$i]";
            }
            if ($i >= $startNum && $cond == 0) {
                print "$array[$i]";
            }
            if ($i > $startNum && $line =~ /$regex/) {
                $cond = 1;
            }
        }
    # case: /3/,4p
    # print the line that start from the line match the regex and end with end number
    # print the line that also match the regex only
    # print other line if flag is no given
    } elsif ($commandArgument =~ /^\/(.+)\/,(\d)p$/) {
        $regex = $1;
        $endNum = $2;
        @array = <STDIN>;
        $previousMatch = 0;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;
            if ($line =~ /$regex/) {
                $previousMatch = 1;
            }
            if ($flag == 0 ) {
                print "$array[$i]";
            }
            if ($i < $endNum && $line !~ /$regex/ && $previousMatch == 1) {
                print "$array[$i]";
            } elsif ($line =~ /$regex/) {
                print "$array[$i]";
            }
        }
    # case: p
    # print the line that start from begin
    # print other line if flag is no given
    } elsif ($argLen == 1) {
        while ($line = <STDIN>) {
            if ($flag == 0) {
                print "$line";
            }
            print "$line";
        }
    # case: /3/,/5/p
    # print the line that start from line that match the first regex, end with line that match the second regex
    # print the other line if flag is no given
    } elsif ($commandArgument =~ /^\/(.+)\/,\/(.+)\/p$/) {
        $regex = $1;
        $regextwo = $2;

        $previousMatch = 0;
        @array = <STDIN>;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;
            if ($flag == 0) {
                print "$line\n";
            }
            if ($line =~ /$regex/ && $previousMatch == 0) {
                print "$line\n";
                $previousMatch = 1;
            } elsif ($line !~ /$regex/ && $line !~ /$regextwo/ && $previousMatch == 1) {
                print "$line\n";
            } elsif ($line =~ /$regextwo/ && $previousMatch == 1) {
                print "$line\n";
                $previousMatch = 0;
            }
        }
    } else {
        print "speed: command line: invalid command\n";
        exit;
    }
}


# function for dealing the sed command when there is a 's' char in the command end
# if there is a g specifed, need to do the sed for all the match 
# if the delimiter is no '/', will also do the sed job, only consider this when command are s/2/3/(option g) 3s/2/4/(option g)
# different dealing method depends on the format of character after or before s
# 1: s/2/3/ (option g)
# 2: 2s/2/3/ (option g)
# 3: /2/s/2/5/ (option g)
# 4: 2,3/s/2/5/ (option g)
# 5: 3,/4/s/4/7/ (option g)
# 6: /4/,4s/4/7/ (optiong g)
# 7: /3/,/4/s/5/7/ (option g)
# $flag = 0 -> no '-n' flag -> do the sed operation for that line that match regex and print 
# $flag = 1 -> has '-n' flag -> print nothing
sub scommand {

    my ($commandArgument, $flag) = @_;
    # if the command start with s 
    if ($commandArgument =~ /^s/) {
        # case: s/2/3/g, s_2_2_g, etc
        # need to consider when the delimiter is no longer '/'
        # find the delimiter and store into $de_one
        if ($commandArgument =~ /^s(.)(.+)(.)g$/) {
            $de_one = $1;
            $de_two = $3;
            if ($de_one ne $de_two) {
                print "speed: command line: invalid command\n";
                exit;
            }
            # do the sed operation for every match case, print if no flag 
            if ($commandArgument =~ /^s\Q$de_one\E(.+)\Q$de_one\E(.*)\Q$de_one\E(g)$/) {
                $regex = $1;
                $replace = $2;
                while ($line = <STDIN>) {
                    chomp $line;
                    $line =~ s/$regex/$replace/g;
                    if ($flag == 0) {
                        print "$line\n";
                    }
                }
            } else {
                print "speed: command line: invalid command\n";
                exit;
            } 
        # only different from the previous case by the g in the end
        } elsif ($commandArgument =~ /^s(.)(.+)(.)$/) {
            $de_one = $1;
            $de_two = $3;
            if ($de_one ne $de_two) {
                print "speed: command line: invalid command\n";
                exit;
            }
    
            if ($commandArgument =~ /^s\Q$de_one\E(.+)\Q$de_one\E(.*)\Q$de_one\E$/) {
                $regex = $1;
                $replace = $2;

                while ($line = <STDIN>) {
                    chomp $line;
                    $line =~ s/$regex/$replace/;
                    if ($flag == 0) {
                        print "$line\n";
                    }
                }
            } else {
                print "speed: command line: invalid command\n";
                exit;
            }   
        } else {
            print "speed: command line: invalid command\n";
            exit;
        }

    # if the commmand start with number and s
    # need to consider when the delimiter is no longer '/'
    } elsif ($commandArgument =~ /^(\d+)s/) {

        # case: 2s/3/4/g, 2s_2_3_g
        # find the delimiter
        if ($commandArgument =~ /^(\d+)s(.)(.+)(.)g$/) {
            $de_one = $2;
            $de_two = $4;
            if ($de_one ne $de_two) {
                print "speed: command line: invalid command\n";
                exit;
            }
            # do the sed operaton only on the line that specifed before s, sed on every match case because of g
            if ($commandArgument =~ /^(\d+)s\Q$de_one\E(.+)\Q$de_one\E(.*)\Q$de_one\E(g)$/) {
                $lineNum = $1;
                $regex = $2;
                $replace = $3;
                # the selected line can not be 0
                if ($lineNum == 0) {
                    print "speed: command line: invalid command\n";
                    exit;
                }
                $i = 0;
                while ($line = <STDIN>) {
                    chomp $line;
                    if ($i == $lineNum-1) {
                        $line =~ s/$regex/$replace/g;
                    }
                    if ($flag == 0) {
                        print "$line\n";
                    }
                    $i++;
                }
            } else {
                print "speed: command line: invalid command\n";
                exit;
            }
        # only different from the previous case by the g in the end   
        } elsif ($commandArgument =~ /^(\d+)s(.)(.+)(.)$/) {
            $de_one = $2;
            $de_two = $4;
            if ($de_one ne $de_two) {
                print "speed: command line: invalid command\n";
                exit;
            }
            if ($commandArgument =~ /^(\d+)s\Q$de_one\E(.+)\Q$de_one\E(.*)\Q$de_one\E$/) {
                $lineNum = $1;
                $regex = $2;
                $replace = $3;
                # the selected line can not be 0
                if ($lineNum == 0) {
                    print "speed: command line: invalid command\n";
                    exit;
                }
                $i = 0;
                while ($line = <STDIN>) {
                    chomp $line;
                    if ($i == $lineNum-1) {
                        $line =~ s/$regex/$replace/;
                    }
                    if ($flag == 0) {
                        print "$line\n";
                    }
                    $i++;
                }
            } else {
                print "speed: command line: invalid command\n";
                exit;
            }   
        } else {
            print "speed: command line: invalid command\n";
            exit;
        }
    # if the command start regex and s
    # case: /2/s/2/5/ (optional g)
    # do the sed operation only on the line that match the regex, sed on everycase if g specifed
    } elsif ($commandArgument =~ /^\/([^\/]+)\/s\/(.+)\/(.*)\/g?$/) {
        $regexOne = $1;
        $regexTwo = $2;
        $replace = $3;
        while ($line = <STDIN>) {
            chomp $line;
            if ($line =~ /$regexOne/) {
                if ($commandArgument =~ /.*\/$/) {
                    $line =~ s/$regexTwo/$replace/;
                } else {
                    $line =~ s/$regexTwo/$replace/g;
                }
            }
            if ($flag == 0) {
                print "$line\n";
            }
        }
    # do the sed operation start from the startNumber and endNUmber, sed on everycase if g specifed
    # apply the sed command to those line
    # case: 2,5s/5/2/ (optional g)
    } elsif ($commandArgument =~ /^(\d),(\d)s\/(.+)\/(.*)\/g?$/) {
        $startNum = $1-1;
        $endNum = $2;
        $regex = $3;
        $replace = $4;
        $flagOne = 0;
        if ($startNum < $endNum) {
            $flagOne = 1;
        }
        $flagTwo = 0;
        if ($commandArgument =~ /.*\/g$/) {
            $flagTwo = 1;
        }
        $i = 0;
        while ($line = <STDIN>) {
            chomp $line;
            if ($flagOne == 1) {
                if ($i >= $startNum && $i < $endNum) {
                    if ($flagTwo == 0) {
                        $line =~ s/$regex/$replace/;
                    } else {
                        $line =~ s/$regex/$replace/g;
                    }
                }
            } else {
                if ($i == $startNum) {
                    if ($flagTwo == 0) {
                        $line =~ s/$regex/$replace/;
                    } else {
                        $line =~ s/$regex/$replace/g;
                    }
                }
            }
            if ($flag == 0) {
                print "$line\n";
            }
            $i++;
        }
    # start from the startNumber and end until we found the line that match the regex
    # lines between that need to be applied the sed command, sed on everycase if g specifed
    # special case when the regex is empty (TODO) (not yet implented, don't have time)
    # case: 3, /5/s/2/3/ (optional g)
    } elsif ($commandArgument =~ /^(\d),\/(.*)\/s\/(.+)\/(.*)\/g?$/) {
        $startNum = $1-1;
        $regex = $2;
        $regextwo = $3;
        $replace = $4;

        $flagOne = 0;
        if ($regex eq "") {
            $flagOne = 1;
        }

        $flagTwo = 0;
        if ($commandArgument =~ /.*\/g$/) {
            $flagTwo = 1;
        }

        $i = 0;
        $found = 0;
        # TODO: When the regex is empty for this case, how to handle this one
        while ($line = <STDIN>) {
            chomp $line;
            if ($flagOne == 1) {
                if ($i >= $startNum && $found == 0) {
                    if ($line =~ /$regextwo/) {
                        if ($flagTwo == 0) {
                            $line =~ s/$regextwo/$replace/;
                        } else {
                            $line =~ s/$regextwo/$replace/g;
                        }
                        $found = 1;
                    } 
                }
            } else {
                if ($i >= $startNum && $found == 0) {
                    if ($flagTwo == 0) {
                        $line =~ s/$regextwo/$replace/;
                    } else {
                        $line =~ s/$regextwo/$replace/g;
                    }
                }
                if ($line =~ /$regex/) {
                    $found = 1;
                }
            }
            if ($flag == 0) {
                print "$line\n";
            }
            $i++;
        }
    # found the line that match the first regex
    # if the line numebr at that time is smaller than the endNumber -> all the line between them need to apply sed command.
    # also need to apply the sed command for rest of lines that match the first regex
    # do the sed for every match case if g specifed
    # case: /3/,2s/2/5/ (optional g)
    } elsif ($commandArgument =~ /^\/(.+)\/,(\d)s\/(.+)\/(.*)\/g?$/) {
        $regex = $1;
        $endNum = $2;
        $regextwo = $3;
        $replace = $4;

        $flagTwo = 0;
        if ($commandArgument =~ /.*\/g$/) {
            $flagTwo = 1;
        }

        $found = 0;
        $i = 0;
        while ($line = <STDIN>) {
            chomp $line;
            if ($line =~ /$regex/) {
                $found = 1;
            }
            if ($found == 1 && $i < $endNum) {
                if ($flagTwo == 0) {
                    $line =~ s/$regextwo/$replace/;
                } else {
                    $line =~ s/$regextwo/$replace/g;
                }
            } elsif ($found == 1 && $i > $endNum) {
                if ($line =~ /$regex/) {
                    if ($flagTwo == 0) {
                        $line =~ s/$regextwo/$replace/;
                    } else {
                        $line =~ s/$regextwo/$replace/g;
                    }
                }
            }
            if ($flag == 0) {
                print "$line\n";
            }
            $i++;
        }
    # do the sed commmand on the line that start match the first regex and end with second regex
    # do the sed operation for every match case
    # case: /3/, /2/s/3/5/ (optional g)
    # the think logicl is same as the case for other /3/, /5/(pd) case
    } elsif ($commandArgument =~ /^\/(.+)\/,\/(.+)\/s\/(.+)\/(.*)\/g?$/) {
        $regex = $1;
        $regextwo = $2;
        $regexthree = $3;
        $replace = $4;

        $flagTwo = 0;
        if ($commandArgument =~ /.*\/g$/) {
            $flagTwo = 1;
        }

        $previousMatch = 0;
        @array = <STDIN>;
        for ($i = 0; $i < @array; $i++) {
            $line = $array[$i];
            chomp $line;

            if ($line =~ /$regex/ && $previousMatch == 0) {
                if ($flagTwo == 0) {
                    $line =~ s/$regexthree/$replace/;
                } else {
                    $line =~ s/$regexthree/$replace/g;
                }
                $previousMatch = 1;
            } elsif ($line !~ /$regex/ && $line !~ /$regextwo/ && $previousMatch == 1) {
                if ($flagTwo == 0) {
                    $line =~ s/$regexthree/$replace/;
                } else {
                    $line =~ s/$regexthree/$replace/g;
                }
            } elsif ($line =~ /$regextwo/ && $previousMatch == 1) {
                if ($flagTwo == 0) {
                    $line =~ s/$regexthree/$replace/;
                } else {
                    $line =~ s/$regexthree/$replace/g;
                }
                $previousMatch = 0;
            }

            if ($flag == 0) {
                print "$line\n";
            }
        }
    # other case, report error
    } else {
        print "speed: command line: invalid command\n";
        exit;
    }
}



sub SetZeroCommandlineArg {
    # first argument is the command line, second argument is for check flag -n is given
    my ($commandArgument, $secondcommandArg) = @_;

    my $flag = $secondcommandArg // 0;

    if ($commandArgument =~ /^-.*/) {
        print "usage: speed [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
        exit;
    }
 
    # situation1: the last char is a command
    if ($commandArgument =~ /[qpd]$/) {
        $commandArgument =~ /([qpd])$/;
        $lastChar = $1;

        my $argLen = length($commandArgument);
        # different situation for different command 'q d p'
        if ($lastChar eq "q") {
            qcommand($argLen, $commandArgument, $flag);
        } elsif ($lastChar eq "d") {
            dcommand($argLen, $commandArgument, $flag);
        } elsif ($lastChar eq "p") {
            pcommand($argLen, $commandArgument, $flag);
        }

    # the first char is a char: consider 's' only since the valid command is 'p d q s'
    } elsif ($commandArgument =~ /s/) {
        scommand($commandArgument, $flag);
    }   

    # TODO: add the speed command error case, (not yet implemented)

}

# I only do the set0 and a bit of set1, therefore for set0 and set1 situation
# there will always be given a single speed command as command line argument
$argNum = @ARGV;


# check the command line argument number is right
if ($argNum == 0) {
    print "usage: speed [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
    exit;
}

# different situation for different command line argument number
if ($argNum == 1) {
    # past it to the function
    SetZeroCommandlineArg($ARGV[0]);

} elsif ($argNum == 2) {
    # depend, pass it to the function with a flag
    if ($ARGV[0] eq '-n') {
        SetZeroCommandlineArg($ARGV[1], 1);
    }
}


# TODO: dealing with multiple command line inside single command line 