# Description
**Sed** is a very complex program which has many commands. It is a important Unix/Linux tool. we implement a few of the most important commands of sed. **Speed** is a POSIX-compatible subset of sed with extended regular expressions (EREs). The Speed is implemented in Perl

# Supported Command 1
## requirement
* speel.pl will be given a single Speed command as a command-line argument. 
* The Speed command will be one of 'q', 'p', 'd', or 's'. The only other command-line argument possible is the -n option. 
* speed.pl need only read from standard input. 
* Speed command can optionally be preceded by an address specifying the line(s) they apply to. This address can either be line number or a regex. line number is a positive number and regex is delimited with slash / characters

### q - quit command
The Speed q command causes speed.pl to exit  
example:  
seq 500 600 | ./speed.pl '/^.+5$/q'  
500  
501  
502  
503  
504  
505  

### p - print command
The Speed p commands prints the input line  
example:  
seq 7 11 | ./speed.pl '4p'
7  
8  
9  
10  
10  
11  

### d - delete command
The Speed d commands deletes the input line  
example:  
seq 11 20 | 2041 speed '/[2468]/d'  
11  
13  
15  
17  
19  

### s - substitute command
The Speed s command replaces the specified regex on the input line. The substitute command can followed optionally by the modifier character g  
example:  
seq 1 5 | 2041 speed 's/[15]/zzz/'  
zzz  
2  
3  
4  
zzz  
seq 100 111 | 2041 speed '/1.1/s/1/-/g'  
100  
-0-  
102  
103  
104  
105  
106  
107  
108  
109  
110  
---  

### -n command line option
The Speed -n command line option stops input lines being printed by default. -n command line option is the only useful in conjunction with the p command.  
example:  
seq 2 3 20 | 2041 speed -n '/^1/p'  
11  
14  
17  

# Supported Command 2
## requirement
* In additional to the previous requirement, $ can be used as an address. 
* Speed commands can optionally be preceded by a comma separated pair of address specifying the start and finish of the range of lines the command applies to. 
* substitue regex are not always delimited with slash / characters. whatever the delimiter is, it will not appear in regexes.

### s - substitute command
any non-whitespace character may be used to delimit a substitute command

### multiple command
multiple Speed commands can be supplied separated by semicolons ; or newlines

# Language
Perl

# How to use
clone the speed.pl to the local computer and use as filter terminal command 

