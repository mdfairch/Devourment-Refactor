ScriptName DevourmentUtil extends Quest conditional
import Logging


;=================================================
; Utility functions.
; Small functions used to do simple but repetitive things.
;


int function boundInt(int val, int min, int max) global
{
	If val is inside of the range [min,max], it will be returned unchanged.
	Otherwise, the result will be clamped to that range.
}
	if val > max
		return max
	elseif val < min
		return min
	else
		return val
	endif
EndFunction


float function BoundFloat(float val, float min, float max) global
{
	If val is inside of the range [min,max], it will be returned unchanged.
	Otherwise, the result will be clamped to that range.
}
	if val > max
		return max
	elseif val < min
		return min
	else
		return val
	endif
EndFunction


int[] function getIntPair(int max) global
{
Returns a pair of integers (unequal to each other) in the range [0,max] (left inclusive).
They will be sorted.
}
	int[] pair = new int[2]
	pair[0] = Utility.RandomInt(0, max - 1)
	pair[1] = Utility.RandomInt(0, max - 1)
	
	if pair[0] == pair[1]
		pair[1] = (pair[1] + 1) % max
	endif
	
	if pair[0] > pair[1]
		int temp = pair[0]
		pair[0] = pair[1]
		pair[1] = temp
	endif
	
	return pair
EndFunction


int Function Poisson(float X) global
	int k = 0
	float p = 1.0
	float L = math.pow(2.71828, -X)

	while p > L 
		k += 1
		p *= PO3_SKSEFunctions.GenerateRandomFloat(0.0, 1.0)
	endwhile

	return k - 1
EndFunction


Bool Function SafeProcess() global
{
	IsInMenuMode to block when game is paused with menus open
	Dialogue Menu check to block when dialog is open
	Console check to block when console is open - console does not trigger IsInMenuMode and thus needs its own check
	Crafting Menu check to block when crafting menus are open - game is not paused so IsInMenuMode does not work
	MessageBoxMenu check to block when message boxes are open - while they pause the game, they do not trigger IsInMenuMode
	ContainerMenu check to block when containers are accessed - while they pause the game, they do not trigger IsInMenuMode
	IsTextInputEnabled check to block when editable text fields are open
}
	return !Utility.IsInMenuMode() \
		&& !UI.IsMenuOpen("Dialogue Menu") \
		&& !UI.IsMenuOpen("Console") \
		&& !UI.IsMenuOpen("Crafting Menu") \
		&& !UI.IsMenuOpen("MessageBoxMenu") \
		&& !UI.IsMenuOpen("ContainerMenu") \
		&& !UI.IsTextInputEnabled()
EndFunction


;=================================================
; Array creation.
;


Actor[] Function createActorArray(int size) global
	if size == 0
		return none
	elseif size == 1
		return new Actor[1]
	elseif size == 2
		return new Actor[2]
	elseif size == 3
		return new Actor[3]
	elseif size == 4
		return new Actor[4]
	elseif size == 5
		return new Actor[5]
	elseif size == 6
		return new Actor[6]
	elseif size == 7
		return new Actor[7]
	elseif size == 8
		return new Actor[8]
	elseif size == 9
		return new Actor[9]
	elseif size == 10
		return new Actor[10]
	elseif size == 11
		return new Actor[11]
	elseif size == 12
		return new Actor[12]
	elseif size == 13
		return new Actor[13]
	elseif size == 14
		return new Actor[14]
	elseif size == 15
		return new Actor[15]
	elseif size == 16
		return new Actor[16]
	elseif size == 17
		return new Actor[17]
	elseif size == 18
		return new Actor[18]
	elseif size == 19
		return new Actor[19]
	elseif size == 20
		return new Actor[20]
	elseif size == 21
		return new Actor[21]
	elseif size == 22
		return new Actor[22]
	elseif size == 23
		return new Actor[23]
	elseif size == 24
		return new Actor[24]
	elseif size == 25
		return new Actor[25]
	elseif size == 26
		return new Actor[26]
	elseif size == 27
		return new Actor[27]
	elseif size == 28
		return new Actor[28]
	elseif size == 29
		return new Actor[29]
	elseif size == 30
		return new Actor[30]
	elseif size == 31
		return new Actor[31]
	elseif size == 32
		return new Actor[32]
	elseif size == 33
		return new Actor[33]
	elseif size == 34
		return new Actor[34]
	elseif size == 35
		return new Actor[35]
	elseif size == 36
		return new Actor[36]
	elseif size == 37
		return new Actor[37]
	elseif size == 38
		return new Actor[38]
	elseif size == 39
		return new Actor[39]
	elseif size == 40
		return new Actor[40]
	elseif size == 41
		return new Actor[41]
	elseif size == 42
		return new Actor[42]
	elseif size == 43
		return new Actor[43]
	elseif size == 44
		return new Actor[44]
	elseif size == 45
		return new Actor[45]
	elseif size == 46
		return new Actor[46]
	elseif size == 47
		return new Actor[47]
	elseif size == 48
		return new Actor[48]
	elseif size == 49
		return new Actor[49]
	elseif size == 50
		return new Actor[50]
	endIf
EndFunction


ObjectReference[] Function createRefArray(int size) global
	if size == 0
		return none
	elseif size == 1
		return new ObjectReference[1]
	elseif size == 2
		return new ObjectReference[2]
	elseif size == 3
		return new ObjectReference[3]
	elseif size == 4
		return new ObjectReference[4]
	elseif size == 5
		return new ObjectReference[5]
	elseif size == 6
		return new ObjectReference[6]
	elseif size == 7
		return new ObjectReference[7]
	elseif size == 8
		return new ObjectReference[8]
	elseif size == 9
		return new ObjectReference[9]
	elseif size == 10
		return new ObjectReference[10]
	elseif size == 11
		return new ObjectReference[11]
	elseif size == 12
		return new ObjectReference[12]
	elseif size == 13
		return new ObjectReference[13]
	elseif size == 14
		return new ObjectReference[14]
	elseif size == 15
		return new ObjectReference[15]
	elseif size == 16
		return new ObjectReference[16]
	elseif size == 17
		return new ObjectReference[17]
	elseif size == 18
		return new ObjectReference[18]
	elseif size == 19
		return new ObjectReference[19]
	elseif size == 20
		return new ObjectReference[20]
	elseif size == 21
		return new ObjectReference[21]
	elseif size == 22
		return new ObjectReference[22]
	elseif size == 23
		return new ObjectReference[23]
	elseif size == 24
		return new ObjectReference[24]
	elseif size == 25
		return new ObjectReference[25]
	elseif size == 26
		return new ObjectReference[26]
	elseif size == 27
		return new ObjectReference[27]
	elseif size == 28
		return new ObjectReference[28]
	elseif size == 29
		return new ObjectReference[29]
	elseif size == 30
		return new ObjectReference[30]
	elseif size == 31
		return new ObjectReference[31]
	elseif size == 32
		return new ObjectReference[32]
	elseif size == 33
		return new ObjectReference[33]
	elseif size == 34
		return new ObjectReference[34]
	elseif size == 35
		return new ObjectReference[35]
	elseif size == 36
		return new ObjectReference[36]
	elseif size == 37
		return new ObjectReference[37]
	elseif size == 38
		return new ObjectReference[38]
	elseif size == 39
		return new ObjectReference[39]
	elseif size == 40
		return new ObjectReference[40]
	elseif size == 41
		return new ObjectReference[41]
	elseif size == 42
		return new ObjectReference[42]
	elseif size == 43
		return new ObjectReference[43]
	elseif size == 44
		return new ObjectReference[44]
	elseif size == 45
		return new ObjectReference[45]
	elseif size == 46
		return new ObjectReference[46]
	elseif size == 47
		return new ObjectReference[47]
	elseif size == 48
		return new ObjectReference[48]
	elseif size == 49
		return new ObjectReference[49]
	elseif size == 50
		return new ObjectReference[50]
	elseif size == 51
		return new ObjectReference[51]
	elseif size == 52
		return new ObjectReference[52]
	elseif size == 53
		return new ObjectReference[53]
	elseif size == 54
		return new ObjectReference[54]
	elseif size == 55
		return new ObjectReference[55]
	elseif size == 56
		return new ObjectReference[56]
	elseif size == 57
		return new ObjectReference[57]
	elseif size == 58
		return new ObjectReference[58]
	elseif size == 59
		return new ObjectReference[59]
	elseif size == 60
		return new ObjectReference[60]
	elseif size == 61
		return new ObjectReference[61]
	elseif size == 62
		return new ObjectReference[62]
	elseif size == 63
		return new ObjectReference[63]
	elseif size == 64
		return new ObjectReference[64]
	elseif size == 65
		return new ObjectReference[65]
	elseif size == 66
		return new ObjectReference[66]
	elseif size == 67
		return new ObjectReference[67]
	elseif size == 68
		return new ObjectReference[68]
	elseif size == 69
		return new ObjectReference[69]
	elseif size == 70
		return new ObjectReference[70]
	elseif size == 71
		return new ObjectReference[71]
	elseif size == 72
		return new ObjectReference[72]
	elseif size == 73
		return new ObjectReference[73]
	elseif size == 74
		return new ObjectReference[74]
	elseif size == 75
		return new ObjectReference[75]
	elseif size == 76
		return new ObjectReference[76]
	elseif size == 77
		return new ObjectReference[77]
	elseif size == 78
		return new ObjectReference[78]
	elseif size == 79
		return new ObjectReference[79]
	elseif size == 80
		return new ObjectReference[80]
	endIf
EndFunction


;=================================================
; Internals.
; Don't touch.
;

;Spell[] property EmptySpell auto


int Function ArrayAddFormEx(Form[] arr, Form val) global
	{ Adds a form to a form array. If the form is already present, its index will be returned. The array will be expended if necessary. }
	int index = arr.find(val)
	if index >= 0
        return index
    endIf

    index = arr.find(none)
    if index < 0 
		int newSize = 1 + (3 * arr.length / 2)
        Utility.ResizeFormArray(arr, newSize, none)

		index = arr.find(none)
		if index < 0 
			return -1
		endIf
    endIf

    arr[index] = val
	return index
endFunction
