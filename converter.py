import sys
import os
import traceback

infile = sys.argv[1]
outfile = sys.argv[2]

NEWLINE = "\n"

class Macro:
    def __init__(self, name, variables):
        self.name = name
        self.variables = variables
        self.lines = []

    def add_line(self, line):
        self.lines.append(line)

    def resolve(self, arguments):
        if len(arguments) != len(self.variables):
            self.warning("Cannot resolve macro '" + self.name + "' too little arguments")
        
        args = dict(zip(self.variables, arguments))

        out = []
        for line in self.lines:
            # I decided to only support 1 var per line, because its 23:57 and 
            # I want this finished quickly
            i = line.find('&')
            if i != -1:
                end = line.find('&', i+1)
                var = line[i+1:end]
                l = line[:i] + args[var] + line[end+1:]
                out.append(l)
            else:
                out.append(line)
        
        out.append('')
        return '\n'.join(out)

class Struct:
    def __init__(self, name):
        self.name = name
        self.size = 0

    def increase_size(self, size):
        self.size += size

class Converter:
    def __init__(self, infile, outfile):
        self.infile_name = infile
        self.inf = open(infile, "r")
        self.outf = open(outfile, "w+")
        self.do_write = True

        self.pushed = []
        self.typetable = {
            "byte": 1,
            "word": 2,
            "dword": 4,
            "db": 1,
            "dw": 2,
            "dd": 4,
        }

        self.macros = {}

        self.localtable = {}
        self.stackframesize = 0
        self.parsing_function = False
        self.recording_macro = None
        self.struct = None
        self.mark_global = False
        self.current_segment = None

        self.globtable = {}

        self.current_linenum = 1
        self.current_line = ""
        self.skip1 = False

    def note(self, reason):
        print(reason)
        print(f"At line {self.current_linenum}\n{self.current_line}\n")

    def warning(self, reason):
        print("WARNING")
        self.note(reason)

    def error(self, reason):
        print("ERROR")
        self.note(reason)
        traceback.print_stack()
        exit(1)

    def get_type_size(self, typename):
        # Pointers are always 32 bit
        if typename.find("PTR") != -1:
            return self.typetable["dword"]

        if typename not in self.typetable:
            self.error(f"type '{typename}' is not found in the typetable, is it defined?"); 
        
        return self.typetable[typename]

    def type_lookup(self, size):
        table = {
            1: 'byte',
            2: 'word',
            4: 'dword'
        }
        if size in table:
            return table[size]

        return ""

    def parse_compat_directive(self, directive):
        if directive == "skip1":
            # Skip the next line and just write it to stdout
            self.skip1 = True
            return None
        return None

    def parse_inline(self, line):
        # replace local references
        local = line.find("@@")
        if local != -1:
            # Locals are only used as memory access [@@localname]
            end = line.find(']')
            if end == -1:
                end = 0
            name = line[local:end]

            if name in self.localtable:
                loc = self.localtable[name][1]
                if loc < 0:
                    loc = str(loc)
                else:
                    loc = "+" + str(loc)

                # We assume there was no type specifier if @@<name> comes right
                # after '['. This is hack but this entire script is one big hack
                # so idc.
                typespecifier = ""
                if line[local-1] == '[':
                    typespecifier = self.type_lookup(self.localtable[name][0])

                return line[:local].replace("ptr ", " ") + typespecifier + " ebp"  + loc + line[end:] + NEWLINE

        # Remove the offset keyword since NASM doesn't need that
        if line.find("offset ") != -1:
            return line.replace("offset", "")

        if self.current_segment == "data":
            if line.find(" dup ") != -1:
                parts = line.split(' ')
                newparts = [parts[0]]
                newparts.append('times')
                newparts.append('(' + parts[2] + ")*" + str(self.get_type_size(parts[1])))
                newparts.append('db 0')

                return " ".join(newparts)
        
        if line.find("ptr ") != -1:
            line = line.replace("ptr ", " ")

        # If there is a memory access we need to make sure it is not 
        memaccess = line.find('[')
        if memaccess != -1:
            end = line.find(']')
            if end == -1:
                self.warning("Memory access not closed?")
                return line
            access = line[memaccess+1:end].strip()
            
            # Assume dword access if not specified
            if len(access.split(' ')) == 1:
                return line[:memaccess+1] + "dword " + line[memaccess+1:]

        return line

    def parse_line(self, line, linenumber):
        self.current_line = line
        self.current_linenum = linenumber

        # Before any other form of processing happens, check if we are recording
        # a macro
        if self.recording_macro is not None:
            # I choose not to support nested macros because fuck that
            if line.startswith("endm"):
                self.recording_macro = None
                return None

            self.recording_macro.add_line(line)
            return None

        line = line.lstrip()
        lineparts = line.split()
        
        if len(lineparts) == 0:
            return "" + NEWLINE

        if self.skip1:
            self.skip1 = False
            return line + NEWLINE

        # Compat directives (if ever necessary)
        if line.startswith(";; compat"):
            # parse a compat directive
            directive = line.split("-")[1]
            return self.parse_compat_directive(directive)

        if line.startswith(';'):
            return NEWLINE

        # Convert structs to NASM form
        if self.struct is not None:
            if lineparts[0] == "ends":
                self.typetable[self.struct.name] = self.struct.size
                self.struct = None
                return "endstruc" + NEWLINE

            # We do not support 'dup' for now.
            regular = {"db": 1, "dw": 2, "dd": 4}
            size = 1
            if lineparts[1] in regular:
                size = regular[lineparts[1]]
            else:
                size = self.get_type_size(lineparts[1])

            self.struct.increase_size(size)

            return "." + lineparts[0] + ": resb " + str(size) + NEWLINE

        # Check if we are opening a struct
        if lineparts[0] == "struc":
            self.struct = Struct(lineparts[1])
            return line + NEWLINE

        # one to one replacements
        specials = {
            "STACK": "",
            "IDEAL": "",
            "P386": "",
            "MODEL": "",
            "ASSUME": "",
            "END": "",
        }
        if lineparts[0] in specials.keys():
            return specials[lineparts[0]] + NEWLINE

        # Macro recording
        if lineparts[0] == "macro":
            macroname = lineparts[1]
            variables = lineparts[2:]
            macro = Macro(macroname, variables)
            self.macros[macroname] = macro
            self.recording_macro = macro
            return None
        
        if lineparts[0] == "CODESEG":
            self.current_segment = "code"
            return "section .text" + NEWLINE
        
        if lineparts[0] == "DATASEG":
            self.current_segment = "data"
            return "section .data" + NEWLINE
        
        if lineparts[0] == "UDATASEG":
            self.current_segment = "data"
            return "section .bss" + NEWLINE

        # Function start
        if lineparts[0] == "proc":
            if self.parsing_function:
                self.warning("Is the previous function closed? (endp not called)")

            self.parsing_function = True
            return lineparts[1] + ":" + NEWLINE + "push ebp" + NEWLINE + "mov ebp, esp" + NEWLINE

        # Function end
        if lineparts[0] == "endp":
            if not self.parsing_function:
                self.warning("Is this even a function? (proc not called)")
            
            self.parsing_function = False
            self.localtable.clear()
            return None

        if lineparts[0] == "GLOBAL":
            # todo: just parse the file instead that makes more sense
            keyword = "extern "
            if self.mark_global:
                keyword = "global "

            name =  lineparts[1].split(':')[0]
            self.globtable[name] = 1

            return keyword + name + NEWLINE
        
        # We do some preprocessor work so we have to include these already
        if lineparts[0] == "include":
            file_to_parse = line.split('"')[1]
            with open(file_to_parse, "r") as f:
                _, f1 = os.path.split(file_to_parse)
                _, f2 = os.path.split(self.infile_name)

                g = self.mark_global
                if f1.split('.')[0].lower() == f2.split('.')[0].lower():
                    self.mark_global = True
                else:
                    self.mark_global = False
                self.mainloop(f)
                self.mark_global = g
            return None

        if lineparts[0] == "arg":
            # strip "returns" directive
            if "returns" in lineparts:
                lineparts = lineparts[:lineparts.index("returns")]

            args = " ".join(lineparts[1:]).split(',')
            newargs = []
            for i, arg in enumerate(args):
                arg = arg.strip()
                if arg == "":
                    continue
                name = arg.split(':')[0].strip()
                size = arg.split(':')[1]
                self.localtable[name] = (4, 8 + 4*i)
                # All arguments are dwords from now on lmao.

            return None 

        # The uses keyword pushes the arguments to the stack and pops them at the end
        if lineparts[0] == "uses":
            self.pushed = line.split("uses ")[1].split(',')
            out = ""
            for arg in self.pushed:
                out += "push " + arg + NEWLINE
            return out

        # The local keyword defines local variables, now we have to resolve them
        if lineparts[0] == "local":
            locs = line.split("local ")[1].split(",")
            self.stackframesize = 0
            tmp = []
            for local in locs:
                name, ltype = local.split(':')
                size = self.get_type_size(ltype)
                tmp.append((name.strip(), (size, self.stackframesize)))
                if size % 4:
                    size += 4 - (size % 4)
                self.stackframesize += size
            
            for name, t in tmp:
                self.localtable[name] = (t[0], -(self.stackframesize - t[1]))
            
            # setup the stack frame
            return "sub esp, " + str(self.stackframesize) + NEWLINE

        if lineparts[0] == "call":
            args = " ".join(lineparts[1:])
            args = args.split(',')
            fname = args[0]
            args = args[1:]
            out = []
            for arg in reversed(args):
                out.append("push dword" + self.parse_inline(arg))
            
            out.append("call " + fname)
            out.append("add esp, " + str(len(args) * 4))
            out.append("")

            return NEWLINE.join(out)

        # The ending of a function
        if lineparts[0] == "ret":
            out = ""
            for arg in reversed(self.pushed):
                out += "pop " + arg + NEWLINE
            out += "leave" + NEWLINE + "ret" + NEWLINE
            self.pushed.clear()
            return out

        # Macro expantion
        if lineparts[0] in self.macros:
            macro = self.macros[lineparts[0]]
            expanded = macro.resolve(lineparts[1:])
            
            out = []
            for line in expanded.split('\n'):
                out.append(self.parse_line(line, linenumber))

            return ''.join(out)

        line = self.parse_inline(line)

        return line + NEWLINE

    def mainloop(self, infile=None):
        if infile is None:
            infile = self.inf
        
        linecount = 1
        for line in infile:
            l = line.strip()
            while len(l) != 0 and l[-1] == '\\':
                l = l[:-1]
                l += next(infile).strip()
                linecount += 1
            outline = self.parse_line(l, linecount)
            if outline is not None and self.do_write:
                self.outf.write(outline)

            linecount += 1

Converter(sys.argv[1], sys.argv[2]).mainloop()