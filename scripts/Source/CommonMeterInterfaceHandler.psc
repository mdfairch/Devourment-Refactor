Scriptname CommonMeterInterfaceHandler extends Quest

Common_SKI_MeterWidget property Meter auto
Actor property PlayerRef auto
GlobalVariable property DebugGlobal auto
{The debug global. 0 = Debug, 1 = Info, 2 = Warning, 3 = Error.}
GlobalVariable property DisplayMode auto
{The display mode global. 0 = Off. 1 = Always On. 2 = Contextual.}
GlobalVariable property DisplayTime auto
{The display time global.}
GlobalVariable property AttributeValue auto
{The global that contains the attribute for this meter.}
GlobalVariable property AttributeMax auto
{The global that contains the maximum value for this attribute.}
GlobalVariable property Opacity auto
{The global that contains the maximum opacity value for this meter.}
GlobalVariable property MainPrimaryColor auto
{Setting global for primary color.}
GlobalVariable property MainSecondaryColor auto
{Setting global for primary color.}
GlobalVariable property AuxPrimaryColor auto
{Setting global for aux (inversion) color.}
GlobalVariable property AuxSecondaryColor auto
{Setting global for aux (inversion) color.}
FormList property RequiredWornFormList auto
{A formlist of armor objects that the player must have equipped for this meter to display.}
GlobalVariable property RequiredSettingGlobal auto
{A global that must be set to 2 for this meter to display.}

bool property lower_is_better = false auto
{By default, contextual mode displays the meter when decreasing below thresholds and always when increasing. Setting this to "true" makes the system display the meter when increasing above thresholds and always when decreasing.}
float property meter_inversion_value = -1.0 auto
{If set, this will cause the meter to fill back up / go back down when this value is reached, usually with an accompanying alternate color. Useful for portraying a "bonus range".}
float property improvement_display_delta_threshold = -1.0 auto
{If the player's attribute improves, we should force the display of the meter, but only if it exceeds this absolute value.}

bool should_update = false
bool meter_displayed = false
int display_iterations_remaining = 0
float last_attribute_value = 0.0

; Set in Creation Kit
float[] property contextual_display_thresholds auto
bool[] property threshold_should_flash auto
bool[] property threshold_should_stay_on auto

Event OnUpdate()
	UpdateMeter()
	if should_update
		RegisterForSingleUpdate(2)
		should_update = false
	endif
EndEvent

Event UpdateMeterDelegate()
	; Called from SKSE Mod Event
	UpdateMeter()
endEvent

function UpdateMeter(bool abForceDisplayIfEnabled = false)
	if RequiredWornFormList && !PlayerRef.IsEquipped(RequiredWornFormList)
		MeterDebug(0, "UpdateMeter failed RequiredWornFormList check.")
		return
	endif
	if RequiredSettingGlobal && RequiredSettingGlobal.GetValue() != 2.0
		MeterDebug(0, "UpdateMeter failed RequiredSettingGlobal check.")
		return
	endif

	HandleMeterUpdate(abForceDisplayIfEnabled)
	if display_iterations_remaining > 0
		display_iterations_remaining -= 1
	endif

	if display_iterations_remaining != 0
		if !should_update
			should_update = true
		endif
	else
		if DisplayMode.GetValueInt() == 2 && meter_displayed
			Meter.FadeTo(0.0, 3.0)
			meter_displayed = false
		endif
	endif
	MeterDebug(0, "DisplayMode " + DisplayMode.GetValueInt() + " abForceDisplayIfEnabled " + abForceDisplayIfEnabled + " display_iterations_remaining " + display_iterations_remaining)
endFunction

function HandleMeterUpdate(bool abForceDisplayIfEnabled = false)
	bool inverted = false
	float attribute_value = AttributeValue.GetValue()
	
	if meter_inversion_value != -1.0
		if lower_is_better && attribute_value < meter_inversion_value
			inverted = true
		elseif !lower_is_better && attribute_value > meter_inversion_value
			inverted = true
		endif
	endif

	if DisplayMode.GetValueInt() == 1 														; Always On
		Meter.Alpha = Opacity.GetValue()
	elseif DisplayMode.GetValueInt() == 2 || abForceDisplayIfEnabled 						; Contextual
		if inverted
			ContextualDisplay(attribute_value)
		else
			ContextualDisplay(attribute_value, abForceDisplayIfEnabled)
		endif
	elseif DisplayMode.GetValueInt() == 0 && display_iterations_remaining == 0
		Meter.Alpha = 0.0
		return
	endif

	int primary_color
	int secondary_color = -1
	if inverted
		primary_color = AuxPrimaryColor.GetValueInt()
		if AuxSecondaryColor
			secondary_color = AuxSecondaryColor.GetValueInt()
		endif
		if lower_is_better
			Meter.SetPercent(1.0 - (attribute_value / meter_inversion_value))
		else
			Meter.SetPercent(1.0 - ((attribute_value - meter_inversion_value) / (AttributeMax.GetValue() - meter_inversion_value)))
		endif
		SetMeterColors(primary_color, secondary_color)
	else
		primary_color = MainPrimaryColor.GetValueInt()
		if MainSecondaryColor
			secondary_color = MainSecondaryColor.GetValueInt()
		endif
		float bonus_range
		if meter_inversion_value == -1.0
			Meter.SetPercent(attribute_value / AttributeMax.GetValue())
		else
			if lower_is_better
				Meter.SetPercent((attribute_value - meter_inversion_value) / (AttributeMax.GetValue() - meter_inversion_value))
			else
				Meter.SetPercent(attribute_value / meter_inversion_value)
			endif
		endif
		SetMeterColors(primary_color, secondary_color)
	endif

	last_attribute_value = attribute_value
endFunction

function ContextualDisplay(float attribute_value, bool abForceDisplayIfEnabled = false)
	if abForceDisplayIfEnabled
		display_iterations_remaining = DisplayTime.GetValueInt()
		MeterDebug(0, "abForceDisplayIfEnabled, returning early from ContextualDisplay.")
		return
	endif

	bool increasing = last_attribute_value < attribute_value

	int i = contextual_display_thresholds.Length - 1
	int current_zone = -1
	while i >= 0
		float threshold_value = contextual_display_thresholds[i]
		float next_threshold_value = 0.0
		if i - 1 >= 0
			next_threshold_value = contextual_display_thresholds[i - 1]
		endif
		if attribute_value <= threshold_value && (attribute_value > next_threshold_value || (attribute_value == 0.0 && next_threshold_value == 0.0))
			current_zone = i
			i = -1
		else
			i -= 1
		endif
	endWhile
	
	if current_zone == -1
		; Abort and return an error. This shouldn't happen.
		MeterDebug(3, "Couldn't determine the current attribute value zone. (Value: " + attribute_value + "). This is bad and you should let the author know.")
		return
	endif

	MeterDebug(0, "current_zone " + current_zone)

	float upper_bound = contextual_display_thresholds[current_zone]
	float lower_bound = 0.0
	if current_zone > 0
		lower_bound = contextual_display_thresholds[current_zone - 1]
	endif
	bool should_flash = threshold_should_flash[current_zone]
	bool should_stay_on = threshold_should_stay_on[current_zone]
	; MeterDebug(0, "AV " + attribute_value + " last AV " + last_attribute_value + " upper_bound " + upper_bound + " lower_bound " + lower_bound + " should_flash " + should_flash + " should stay on " + should_stay_on)
	if lower_is_better
		if increasing && last_attribute_value <= lower_bound && attribute_value > lower_bound
			if should_stay_on
				MeterFadeUp(-1, should_flash)
				MeterDebug(0, "Contextual Display - Case A")
			else
				MeterFadeUp(DisplayTime.GetValueInt(), should_flash)
				MeterDebug(0, "Contextual Display - Case B")
			endif
		elseif !increasing && (last_attribute_value - attribute_value >= Math.Abs(improvement_display_delta_threshold))
			MeterFadeUp(-1)
			MeterDebug(0, "Contextual Display - Case H")
		elseif !should_stay_on
			if display_iterations_remaining == -1
				display_iterations_remaining = DisplayTime.GetValueInt()
				MeterDebug(0, "Contextual Display - Case C")
			endif
		endif
	else
		if !increasing && last_attribute_value > upper_bound && attribute_value <= upper_bound
			if should_stay_on
				MeterFadeUp(-1, should_flash)
				MeterDebug(0, "Contextual Display - Case D")
			else
				MeterFadeUp(DisplayTime.GetValueInt(), should_flash)
				MeterDebug(0, "Contextual Display - Case E")
			endif
		elseif increasing && (attribute_value - last_attribute_value >= Math.Abs(improvement_display_delta_threshold))
			MeterFadeUp(-1)
			MeterDebug(0, "Contextual Display - Case F")
		elseif !should_stay_on
			if display_iterations_remaining == -1
				display_iterations_remaining = DisplayTime.GetValueInt()
				MeterDebug(0, "Contextual Display - Case G")
			endif
		endif
	endif
endFunction

function MeterFadeUp(int iterations_remaining, bool flash = false)
	if DisplayMode.GetValueInt() == 0
		return
	endif
	meter_displayed = true
	Meter.FadeTo(Opacity.GetValue(), 2.0)
	if flash
		Utility.Wait(1.0)
		Meter.StartFlash()
	endIf
	display_iterations_remaining = iterations_remaining
	RegisterForSingleUpdate(2)
endFunction

function SetMeterColors(int aiPrimaryColor, int aiSecondaryColor)
	if Meter.PrimaryColor != aiPrimaryColor
		if aiSecondaryColor == -1
			Meter.SetColors(aiPrimaryColor, ColorComponent.SetValue(aiPrimaryColor, 0.85))
		else
			Meter.SetColors(aiPrimaryColor, aiSecondaryColor)
		endif
	endIf
endFunction

Event ForceMeterDisplay(bool flash = false)
	if RequiredWornFormList && !PlayerRef.IsEquipped(RequiredWornFormList)
		MeterDebug(0, "ForceMeterDisplay failed RequiredWornFormList check.")
		return
	endif
	if RequiredSettingGlobal && RequiredSettingGlobal.GetValue() != 2.0
		MeterDebug(0, "ForceMeterDisplay failed RequiredSettingGlobal check.")
		return
	endif
	MeterFadeUp(DisplayTime.GetValueInt(), flash)
	UpdateMeter(true)
endEvent

Event RemoveMeter()
	Meter.Alpha = 0.0
endEvent

Event CheckMeterRequirements()
	if RequiredWornFormList && !PlayerRef.IsEquipped(RequiredWornFormList)
		MeterDebug(0, "CheckMeterRequirements failed RequiredWornFormList check.")
		RemoveMeter()
	endif
	if RequiredSettingGlobal && RequiredSettingGlobal.GetValue() != 2.0
		MeterDebug(0, "CheckMeterRequirements failed RequiredSettingGlobal check.")
		RemoveMeter()
	endif
endEvent

function MeterDebug(int aiSeverity, string asLogMessage)
	int LOG_LEVEL = DebugGlobal.GetValueInt()
	if LOG_LEVEL <= aiSeverity
		if aiSeverity == 0
			debug.trace("[" + self + "][Debug] " + asLogMessage)
		elseif aiSeverity == 1
			debug.trace("[" + self + "][Info] " + asLogMessage)
		elseif aiSeverity == 2
			debug.trace("[" + self + "][Warning] " + asLogMessage)
		elseif aiSeverity == 3
			debug.trace("[" + self + "][ERROR] " + asLogMessage)
		endif
	endif
endFunction