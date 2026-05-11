Config = {}

-- Players can use police commands if they either have this ACE permission
-- or one of their identifiers is listed in Config.PoliceIdentifiers.
Config.AcePermission = 'police.use'
Config.PoliceIdentifiers = {
    -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    -- 'discord:123456789012345678'
}

Config.RequireDutyForActions = true
Config.InteractDistance = 3.0
Config.MaxFineAmount = 50000
Config.MaxJailMinutes = 120

Config.JailReleasePosition = vector3(425.1, -979.5, 30.7)
Config.JailSpawnPosition = vector3(459.9, -994.3, 24.9)

Config.DispatchBlipDurationMs = 45000
Config.DispatchBlipSprite = 161
Config.DispatchBlipColor = 1
Config.DispatchBlipScale = 1.0
