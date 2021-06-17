Config = {}
Config.Locale = 'fr'

Config.Accounts = {
	bank = _U('account_bank'),
	black_money = _U('account_black_money'),
	money = _U('account_money')
}

Config.StartingAccountMoney = {
  bank = 8000,
  black_money = 0,
  money = 2000
}

Config.EnableSocietyPayouts = true -- pay from the society account that the player is employed at? Requirement: esx_society
Config.EnableHud            = false -- enable the default hud? Display current job and accounts (black, bank & cash)
Config.MaxWeight            = 24   -- the max inventory weight without backpack
Config.PaycheckInterval     = 30 * 60000 -- how often to recieve pay checks in milliseconds
Config.EnableDebug          = false
-- © Aide FiveM | Discord : https://discord.gg/puEzjM8