-- Changelog --
-- 2019-10-09: First version considered done.
-- 2019-10-10: Added, clear all values when Esc key is pressed two times. 
--             Changed button icons due to graphical glitch on hand held unit.
-- 2019-10-13: Fixed program crash during split screen.
--             Lowered time ticks to 200 ms. 100 ms caused flickering and glitches on hand held unit.
--             Bug: Do clear by Esc or c. Leave all boxes empty and enter a number in F and press Enter. Calculation will be done and answer returned using "old" values. Fix: Set all values in inpexptable[i] to nil during clear.
--             Changed as many variabels as safely possible to local. (I didn't want to poke the bear to much.)
--             Added red button for checklin error.
--             Added borders around input boxes. Blue border on active box and grey border on inactive boxes.
--             Discovered that Lua does not understand (-) "negative", char(8722) as a number. - "minus" char(45) must be used for negative numbers. Updated function inpexp() to convert (-) to -. Why the hell does not Lua on Nspire support (-) out of box?
-- 2019-10-27: Updated "split screen warning" to include min/max screen ratio, not only minimum height. 
--             Changed mouse hover button color to light grey instead of dark grey

-- Minimum requirements: TI Nspire CX CAS (color resulution 318x212)

-- https://en.wikipedia.org/wiki/Linear_interpolation

-- Potential issues within code --
-- If rows or clns is set to 0 it will cause division by zero. Only affects typo during app design.
-- Code does not check for device compability other then trough apilevel requirement. CAS is required for solving equation.

platform.apilevel = '2.4'
local appversion = "191027" -- Made by: Fredrik Ekelöf, fredrik.ekelof@gmail.com

-- Grid layout configuration
local lblhdg = "Linear Interpolation" -- Heading text
local clns = 2 -- Total number of columns
local rows = 4 -- Total number of rows
local padding = 10 -- Free space in pixels between each square
local gridassist = 0 -- Turn on/off grid assistent by 0/1

-- Font size configuration. Availible sizes are 7,9,10,11,12,16,24
-- Font size is scaled relative to size displayd on hand held unit
local fnthdgset = 12 -- Heading font size 
local fntbodyset = 10 -- Label and body text font size 

-- Colors
local bgcolor = 0xCFE2F3 -- Background, Light blue
local brdcoloract = 0x2478CF -- Active box border, blue
local brdcolorinact = 0xEBEBEB -- Inactive box border, grey 
local errorcolor = 0xF02600 -- Error text, Dark Red

-- Variabels for internal use
local setfocus = 1 -- Sets focus in box A when program launches
local fnthdg,fntbody = fnthdgset,fntbodyset -- Working fonts used by program
local inpidtable = {} -- Initial empty table for storing input boxes unique ID:s
local inpexptable = {} -- Initial empty table for storing input boxes values
local btnclick = false -- Tracks if button is being clicked
local btnhover = false -- Tracks if mouse hovers over button
local escrst = 0 -- Tracks how many times Esc key has been pressed
local esccounter = 0 -- Timer for Esc key press reset
local enterpress = false -- Tracks if Enter key is being pressed in box F
local entercounter = 0 -- Timer for calc button blue flash when pressing Enter key
local chkx0 = nil -- Checks if x occurs zero times in equation
local chkx2 = nil -- Checks if x occurs more then once in equation
local checklin = nil -- Checks if equation is linear
local printans = nil -- Checks if final answer shall be printed
local calcans = nil -- Final answer

-- Screen properties
local scr = platform.window -- Shortcut
local scrwh,scrht = scr:width(),scr:height() -- Stores screen dimensions

-- Icons for buttons (original icon size is 63x32 px)
buttonblue = image.new(_R.IMG.buttonblue)
buttongrey = image.new(_R.IMG.buttongrey)
buttonred = image.new(_R.IMG.buttonred)
buttonwhite = image.new(_R.IMG.buttonwhite)

function on.construction()

    timer.start(1/5) -- Starts timer with 5 ticks per second

    -- Sets background colour
    scr:setBackgroundColor(bgcolor)

    -- Defines input boxes variabels, var = inputbox(ID,"label text",row,column)
    inpa = inpbox(1,"A = ",1,1)
    inpb = inpbox(2,"B = ",1,2)
    inpc = inpbox(3,"C = ",1,3)
    inpd = inpbox(4,"D = ",2,1)
    inpe = inpbox(5,"E = ",2,2)
    inpf = inpbox(6,"F = ",2,3)

    -- Defines Calc button, btnname = button(ID,"label text",x-pos,y-pos,width,height)
    btncalc = button(1,"Calc",252,175,56,26)
    
    -- Sets focus in box A when program launches
    inpidtable[1]:setFocus()

end

-- Shortcut for update/refresh screen
function scrupdate()

    return scr:invalidate()
    
end

function on.timer() -- Updates screen 5 times per second

    scrupdate()
    
    -- Sets focus in box A when program launches
    if setfocus == 1 then    
        inpidtable[1]:setBorderColor(brdcoloract)
        inpidtable[1]:setFocus()
        setfocus = 0 -- Reset focus
    end
    
end

function on.resize()

    -- Fetches new screen dimensions when window resizes
    scrwh,scrht = scr:width(),scr:height()

    -- Adjust font size depending on screen size
    if scrwh >= 318 then
        fnthdg = fnthdgset*scrwh/318
        fntbody = fntbodyset*scrwh/318
     else
        fnthdg = 7
        fntbody = 7
     end
     
    -- Prints input boxes to above defined variabels
    inpa:editor()
    inpb:editor()
    inpc:editor()
    inpd:editor()
    inpe:editor()
    inpf:editor()

    -- Makes border remain black in active box
    for i = 1,6 do
        if inpidtable[i]:hasFocus() == true then
            inpidtable[i]:setBorderColor(brdcoloract)
        end
    end

end

function on.paint(gc)

    -- Prints app version at bottom of page
    gc:setFont("sansserif","r",9)
    gc:drawString("Version: "..appversion,0,scrht,"bottom")

    -- Prints heading
    gc:setFont("sansserif","b",fnthdg) -- Heading font
    lblhdgwh,lblhdght = gc:getStringWidth(lblhdg),gc:getStringHeight(lblhdg) -- Fetches string dimensions
    if scrht/scrwh < 0.65 or scrht/scrwh > 0.69 or scrht < 212 then
        gc:drawString("Screen ratio not supported!",0,0,"top") -- Prints warning
    else
        gc:drawString(lblhdg,scrwh/2-lblhdgwh/2,0,"top") -- Prints heading
    end
    gc:setPen("thin", "dotted")
    gc:drawLine(0,lblhdght,scrwh,lblhdght) -- Draws line below heading
    
    -- Prints labels to above defined input boxes
    inpa:lblpaint(gc)
    inpb:lblpaint(gc)
    inpc:lblpaint(gc)
    inpd:lblpaint(gc)
    inpe:lblpaint(gc)
    inpf:lblpaint(gc)

    -- Prints calc button
    btncalc:paint(gc)

    -- Be aware, x and y coordinates are adjusted manually. Use grid assistent to fit content on screen.
    -- Prints error if there is zero x in equation
    if chkx0 == 1 then
        gc:setFont("sansserif","r",fntbody)
        gc:setColorRGB(errorcolor)
        gc:drawString("1 variabel must be x",10*scrwh/318,170*scrht/212,"top")
    end

    -- Be aware, x and y coordinates are adjusted manually. Use grid assistent to fit content on screen.
    -- Prints error if there is more then one x in equation
    if chkx2 == 1 then
        gc:setFont("sansserif","r",fntbody)
        gc:setColorRGB(errorcolor)
        gc:drawString("Only 1 variabel can be x",10*scrwh/318,170*scrht/212,"top")
    end
    
    -- Be aware, x and y coordinates are adjusted manually. Use grid assistent to fit content on screen.
    -- Prints error if equation is not linear
    if checklin == 1 and chkx0 == 0 and chkx2 == 0 then
        gc:setFont("sansserif","r",fntbody)
        gc:setColorRGB(errorcolor)
        gc:drawString("Equation is not linear",10*scrwh/318,170*scrht/212,"top")
    end

    -- Be aware, x and y coordinates are adjusted manually. Use grid assistent to fit content on screen.
    -- Prints final answer for x
    if printans == 1 then
        gc:setFont("sansserif","r",fntbody)
        gc:setColorRGB(0x000000)
        gc:drawString("x = "..calcans,10*scrwh/318,170*scrht/212,"top")
    end

    -- Prints grid pattern assistent
    if gridassist == 1 then
        gc:setColorRGB(0x000000)
        for i = 1, clns do
            -- Prints column borders
            gc:setPen("thin", "smooth")
            gc:drawLine(scrwh*i/clns,0,scrwh*i/clns,scrht)
            -- Prints column padding area
            gc:setPen("thin", "dashed")
            -- Left padding edge
            gc:drawLine(scrwh*i/clns-scrwh/clns+padding,0,scrwh*i/clns-scrwh/clns+padding,scrht)
            -- Right padding edge     
            gc:drawLine(scrwh*i/clns-padding,0,scrwh*i/clns-padding,scrht)
        end
        for i = 1, rows do
            -- Prints row borders
            local scrht = scrht-lblhdght
            gc:setPen("thin", "smooth")
            gc:drawLine(0,lblhdght,scrwh,lblhdght)
            gc:drawLine(0,lblhdght+scrht*i/rows,scrwh,lblhdght+scrht*i/rows)
            -- Prints row padding area
            gc:setPen("thin", "dashed")
            -- Top padding area
            gc:drawLine(0,lblhdght+scrht*i/rows-scrht/rows+padding,scrwh,lblhdght+scrht*i/rows-scrht/rows+padding)
            -- Bottom padding area
            gc:drawLine(0,lblhdght+scrht*i/rows-padding,scrwh,lblhdght+scrht*i/rows-padding)
        end
    end

    -- Resets Esc key button press after 500 ms
    if esccounter < timer.getMilliSecCounter()  then
        escrst = 0
    end

end

-- Checks heading string size outside of paint function
function gethdgsize(str,gc)

    gc:setFont("sansserif","b",fnthdg)
    local strwh,strht = gc:getStringWidth(str),gc:getStringHeight(str)
    return strwh,strht

end

-- Checks label string size outside of paint function
function getlblsize(str,gc)

    gc:setFont("sansserif","r",fntbody)
    local strwh,strht = gc:getStringWidth(str),gc:getStringHeight(str)
    return strwh,strht

end

-- Class specifies how and where input boxes and labels shall be printed on screen
inpbox = class()

function inpbox:init(id,lbl,cln,row)

    self.id = id
    self.lbl = lbl
    self.cln = cln
    self.row = row
    self.boxid = D2Editor.newRichText() -- Generates the input box
    inpidtable[id] = self.boxid -- Stores input box unique ID

end

function inpbox:lblpaint(gc)

    local scrht = scrht-lblhdght

    -- Properties for labels
    gc:setFont("sansserif","r",fntbody)
    gc:drawString(self.lbl,scrwh*self.cln/clns-scrwh/clns+padding,lblhdght+scrht*self.row/rows-scrht/rows+padding,"top")

end

function inpbox:editor()

    -- Verifies if an input value is a valid number. Returns red colored expression if not OK.
    function inpexp()
        
        local boxexp = self.boxid:getExpression()
        
        printans = 0 -- Clears final answer
        chkx0 = 0 -- Clears error message
        chkx2 = 0 -- Clears error message
        checklin = 0 -- Clears error message

        -- Converts (-) "negative" char(8722) to - "minus" char(45). Lua does not understand (-) as a number.
        if boxexp ~= nil then
            boxexp = boxexp:gsub(string.uchar(8722),"-")
        end

        -- Converts input expression to a number
        if boxexp == "x" then -- Checks if variable is x, marks it as OK
            inpexptable[self.id] = "x"
            self.boxid:setTextColor(0x000000)
            self.boxid:setMainFont("sansserif","r",fntbody)
        elseif boxexp == "-" then -- Checks if variable is minus sign char(45), marks it as OK
            inpexptable[self.id] = "-"
            self.boxid:setTextColor(0x000000)
            self.boxid:setMainFont("sansserif","r",fntbody)
         else        
            inpexptable[self.id] = tonumber(boxexp)
            if inpexptable[self.id] == nil then -- Flags expression in red text if not a number
                self.boxid:setTextColor(errorcolor)
                self.boxid:setMainFont("sansserif","i",fntbody)
            else -- If number is OK, then text is set to normal black.
                self.boxid:setTextColor(0x000000)
                self.boxid:setMainFont("sansserif","r",fntbody)
            end
        end

    end
    
    -- Fetches string sizes of heading and labels
    local lblwh,lblht = platform.withGC(getlblsize,self.lbl)
    local hdgwh,hdght = platform.withGC(gethdgsize,lblhdg)

    local scrht = scrht-hdght

    -- Properties for input boxes
    self.boxid:setMainFont("sansserif","r",fntbody)
    self.boxid:move(lblwh+scrwh*self.cln/clns-scrwh/clns+padding,hdght+scrht*(self.row-1)/rows+padding)
    self.boxid:resize(scrwh/clns-lblwh-2*padding,27+2*(fntbody-10)) -- Height formula concluded from different screen size tests
    self.boxid:setBorder(1)
    self.boxid:setBorderColor(brdcolorinact) -- Default border color
    self.boxid:setDisable2DinRT(true) -- Disables mathprint
    self.boxid:setColorable(false) -- Disables manual colors
    self.boxid:setWordWrapWidth(-1) -- Disables word wrap
    self.boxid:setTextChangeListener(inpexp) -- Checks function inpexp() during writing
    self.boxid:registerFilter { -- Keyboard/mouse actions
        tabKey = function()  -- Moves curser to next input box
            if self.id >= 1 and self.id <= 5 then
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[self.id+1]:setBorderColor(brdcoloract)
                inpidtable[self.id+1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[1]:setBorderColor(brdcoloract)
                inpidtable[1]:setFocus()
                return true
            end
        end,
        backtabKey = function() -- Moves curser to previous input box
            if self.id >= 2 and self.id <= 6 then
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[self.id-1]:setBorderColor(brdcoloract)
                inpidtable[self.id-1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[6]:setBorderColor(brdcoloract)
                inpidtable[6]:setFocus()
                return true
            end
        end,
        arrowDown = function() -- Moves curser to next input box
            if self.id >= 1 and self.id <= 5 then
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[self.id+1]:setBorderColor(brdcoloract)
                inpidtable[self.id+1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[1]:setBorderColor(brdcoloract)
                inpidtable[1]:setFocus()
                return true
            end
        end,
        arrowUp = function() -- Moves curser to previous input box
            if self.id >= 2 and self.id <= 6 then
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[self.id-1]:setBorderColor(brdcoloract)
                inpidtable[self.id-1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[6]:setBorderColor(brdcoloract)
                inpidtable[6]:setFocus()
                return true
            end
        end,
        escapeKey = function() -- Clears all values when Esc is being pressed quickly two times
            esccounter = timer.getMilliSecCounter()+500
            escrst = escrst+1
            if escrst == 2 then
                for i = 1,6 do
                    inpidtable[i]:setText("")
                    inpexptable[i] = nil
                end
            self.boxid:setBorderColor(brdcolorinact)
            inpidtable[1]:setBorderColor(brdcoloract)
            inpidtable[1]:setFocus() -- Focus is set in box A
            escrst = 0 -- Resets counter
            printans = 0 -- Clears final answer
            chkx0 = 0 -- Clears error message
            chkx2 = 0 -- Clears error message
            checklin = 0 -- Clears error message
            end
        end,
        enterKey = function() -- Move curser to next input box or perform calculations
            if self.id >= 1 and self.id <= 5 then
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[self.id+1]:setBorderColor(brdcoloract)
                inpidtable[self.id+1]:setFocus()
                return true
            else
                entercounter = timer.getMilliSecCounter()+200 -- Triggers calc button blue flash
                -- Clears all values when c is entered in box F and Enter key is pressed
                if self.boxid:getExpression() == "c" then
                    for i = 1,6 do
                        inpidtable[i]:setText("")
                        inpexptable[i] = nil
                    end
                    self.boxid:setBorderColor(brdcolorinact)
                    inpidtable[1]:setBorderColor(brdcoloract)
                    inpidtable[1]:setFocus() -- Focus is set in box A
                else
                    calculate()
                    inpidtable[6]:setFocus() -- Garanties curser remains in box F
                    return true
                end
            end
        end,
        returnKey = function()  -- Move curser to next input box or perform calculations
            if self.id >= 1 and self.id <= 5 then
                self.boxid:setBorderColor(brdcolorinact)
                inpidtable[self.id+1]:setBorderColor(brdcoloract)
                inpidtable[self.id+1]:setFocus()
                return true
            else
                entercounter = timer.getMilliSecCounter()+200 -- Triggers calc button blue flash
                -- Clears all values when c is entered in box F and Enter key is pressed
                if self.boxid:getExpression() == "c" then
                    for i = 1,6 do
                        inpidtable[i]:setText("")
                        inpexptable[i] = nil
                    end
                    self.boxid:setBorderColor(brdcolorinact)
                    inpidtable[1]:setBorderColor(brdcoloract)
                    inpidtable[1]:setFocus() -- Focus is set in box A
                else
                    calculate()
                    inpidtable[6]:setFocus() -- Garanties curser remains in box F
                    return true
                end
            end
        end,
        mouseDown = function() -- Moves curser to clicked input box
            if inpidtable[self.id]:hasFocus() == false then
                for i = 1,6 do
                    inpidtable[i]:setBorderColor(brdcolorinact)
                end
                inpidtable[self.id]:setBorderColor(brdcoloract)
            end
            return false -- Must be false, otherwise not possible to select text with mouse
        end
    } -- End of keyboard/mouse actions

end

-- Class defines button properties and actions
button = class()

function button:init(id,lbl,x,y,wh,ht)

    self.id = id
    self.lbl = lbl
    self.x = x
    self.y = y
    self.wh = wh
    self.ht = ht
    self.selected = false

end

function button:paint(gc)

    local btnlblwh,btnlblht = platform.withGC(gethdgsize,self.lbl)

    -- Calc button will flash for 200 ms
    if timer.getMilliSecCounter() < entercounter then
    enterpress = true
    else
    enterpress = false
    end

    -- Makes button blue during mouse click and Enter key press
    if btnclick == true or enterpress == true then
        buttonblue = buttonblue:copy(self.wh*scrwh/318,self.ht*scrht/212)
        gc:drawImage(buttonblue,self.x*scrwh/318,self.y*scrht/212)
        gc:setFont("sansserif","b",fnthdg)
        gc:setColorRGB(0xFFFFFF)
        gc:drawString(self.lbl,self.x*scrwh/318+self.wh*scrwh/318/2-btnlblwh/2,self.y*scrht/212+self.ht*scrht/212/2-btnlblht/2,"top")
    else -- Normal mode, white button with black text
        buttonwhite = buttonwhite:copy(self.wh*scrwh/318,self.ht*scrht/212)
        gc:drawImage(buttonwhite,self.x*scrwh/318,self.y*scrht/212)
        gc:setFont("sansserif","r",fnthdg)
        gc:setColorRGB(0x000000)
        gc:drawString(self.lbl,self.x*scrwh/318+self.wh*scrwh/318/2-btnlblwh/2,self.y*scrht/212+self.ht*scrht/212/2-btnlblht/2,"top")
    end

    -- Makes button gray on mouse hover 
    if btnhover == true and btnclick == false and enterpress == false then
        buttongrey = buttongrey:copy(self.wh*scrwh/318,self.ht*scrht/212)
        gc:drawImage(buttongrey,self.x*scrwh/318,self.y*scrht/212)
        gc:setFont("sansserif","b",fnthdg)
        gc:setColorRGB(0x000000)
        gc:drawString(self.lbl,self.x*scrwh/318+self.wh*scrwh/318/2-btnlblwh/2,self.y*scrht/212+self.ht*scrht/212/2-btnlblht/2,"top")
    end

    -- Makes button red on errors
    if chkx0 == 1 or chkx2 == 1 or checklin == 1 then
        buttonred = buttonred:copy(self.wh*scrwh/318,self.ht*scrht/212)
        gc:drawImage(buttonred,self.x*scrwh/318,self.y*scrht/212)
        gc:setFont("sansserif","b",fnthdg)
        gc:setColorRGB(0xFFFFFF)
        gc:drawString(self.lbl,self.x*scrwh/318+self.wh*scrwh/318/2-btnlblwh/2,self.y*scrht/212+self.ht*scrht/212/2-btnlblht/2,"top")
    end

end

function button:click(mx,my)

    -- Returns true or false depending on mouse position 
    return mx >= self.x*scrwh/318 and mx <= self.x*scrwh/318+self.wh*scrwh/318 and my >= self.y*scrht/212 and my <= self.y*scrht/212+self.ht*scrht/212

end

-- Tracks mouse movement
function on.mouseMove(mx,my)

    -- Sends command to make button grey
    if btncalc:click(mx,my) then
        btnhover = true
    else
        btnhover = false
    end 

end

function on.mouseUp(mx,my)

    -- Sends command to make button white when mouse button is released
    btnclick = false

end

function on.mouseDown(mx,my)

    -- Sends command to make button blue during mouse button clicks
    if btncalc:click(mx,my) then
        btnclick = true
        calculate() -- Sends command to complete final calculation
    end

end

-- Solves linear interpolation equation
function calculate()

    -- Internal variabels for validating equation
    local checkx = 0 -- To check how many variabels contains x is in equation
    local checknum = 0 -- To check how many variabels contains numbers in equation

    -- Variabels used in equation
    local calca = inpexptable[1]
    local calcb = inpexptable[2]
    local calcc = inpexptable[3]
    local calcd = inpexptable[4]
    local calce = inpexptable[5]
    local calcf = inpexptable[6]

    -- Checks how many x exist in equation
    for i = 1,6 do
        if inpexptable[i] == "x" then
            checkx = checkx+1
        end
     end

    -- Checks how many numbers exist in equation
    for i = 1,6 do
        if type(inpexptable[i]) == "number" then
            checknum = checknum+1
        end
    end

    -- Sends print command to show warning message "1 variabel must be x"
    if checkx == 0 or checkx == nil then
        chkx0 = 1 -- Warning
    else
        chkx0 = 0 -- No warning
    end

    -- Sends print command to show warning message "Only 1 variabel can be x"
    if checkx > 1 then
        chkx2 = 1 -- Warning
    else
        chkx2 = 0 -- No warning
    end

    -- Validates if equation is linear
    if chkx0 == 0 and chkx2 == 0 and checknum == 5 then
        local chklinstr1 = "when("..calca.."<"..calcb..">"..calcc..",1,0,0)"
        local chklinstr2 = "when("..calca..">"..calcb.."<"..calcc..",1,0,0)"
        local chklinstr3 = "when("..calcd.."<"..calce..">"..calcf..",1,0,0)"
        local chklinstr4 = "when("..calcd..">"..calce.."<"..calcf..",1,0,0)"
        local chklinstr5 = "when("..calca.."-"..calcb.."=0,1,0,0)"
        local chklinstr6 = "when("..calcb.."-"..calcc.."=0,1,0,0)"
        local chklinstr7 = "when("..calca.."-"..calcc.."=0,1,0,0)"
        local chklinstr8 = "when("..calcd.."-"..calce.."=0,1,0,0)"
        local chklinstr9 = "when("..calce.."-"..calcf.."=0,1,0,0)"
        local chklinstr10 = "when("..calcd.."-"..calcf.."=0,1,0,0)"
        local chklinans =  math.eval(chklinstr1)+math.eval(chklinstr2)+math.eval(chklinstr3)+math.eval(chklinstr4)+math.eval(chklinstr5)+math.eval(chklinstr6)+math.eval(chklinstr7)+math.eval(chklinstr8)+math.eval(chklinstr9)+math.eval(chklinstr10)

        -- Sends print command to show warning message "Equation is not linear"
        if chklinans ~= 0 then
            checklin = 1 -- Warning
        else
            checklin = 0 -- No warning
        end  
    end

    -- Completes final equation if 5 linear variabels contains numbers and one variabel contains x 
    if checkx == 1 and checknum == 5 and checklin == 0 then
        -- Converts equation to a string used by TI math engine, (a-b)/(a-c)=(d-e)/(d-f)
        local calcstr = "right(solve(("..calca.."-"..calcb..")/("..calca.."-"..calcc..")=("..calcd.."-"..calce..")/("..calcd.."-"..calcf.."),x))"
        calcans = math.eval(calcstr) -- Solves equation using TI math engine 
        if tonumber(calcans) == nil then
            calcans = "Error in CAS math engine"
        end
        printans = 1 -- Sends print command to show 
    end

end