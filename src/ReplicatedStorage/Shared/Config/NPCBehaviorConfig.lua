--[[
NPCBehaviorConfig
- Single source of truth untuk spawn weights, animasi, dan parameter behavior NPC.
- Semua nilai ID animasi di bawah adalah placeholder; ganti saat aset final siap.
]]

local NPCBehaviorConfig = {}

NPCBehaviorConfig.SchemaVersion = "1.1.0"
NPCBehaviorConfig.DefaultProfile = "Day"
NPCBehaviorConfig.RequiredProfiles = {
	Day = true,
	Night = true,
	EventAnomaly = true,
}
NPCBehaviorConfig.SupportedClasses = {
	normal = true,
	anomaly = true,
	meme = true,
}

NPCBehaviorConfig.SpawnProfiles = {
	Day = {
		normal = 72,
		anomaly = 8,
		meme = 20,
	},
	Night = {
		normal = 45,
		anomaly = 35,
		meme = 20,
	},
	EventAnomaly = {
		normal = 15,
		anomaly = 70,
		meme = 15,
	},
}

NPCBehaviorConfig.SpawnPolicy = {
	maxActiveGlobal = 25,
	maxActiveByClass = {
		normal = 12,
		anomaly = 8,
		meme = 8,
	},
}

NPCBehaviorConfig.NPCs = {
	-- Normal NPC
	{
		id = "customer_regular",
		displayName = "Pelanggan Biasa",
		class = "normal",
		spawnWeight = 45,
		modelName = "CustomerRegular",
		animations = {
			idle = "rbxassetid://00000001",
			walk = "rbxassetid://00000002",
			emote = "rbxassetid://00000003",
		},
		behavior = {
			type = "browse_computers",
			moveSpeed = 12,
			patienceSeconds = 45,
		},
	},
	{
		id = "student_gamer",
		displayName = "Anak Sekolah Mabar",
		class = "normal",
		spawnWeight = 30,
		modelName = "StudentGamer",
		animations = {
			idle = "rbxassetid://00000004",
			walk = "rbxassetid://00000005",
			emote = "rbxassetid://00000006",
		},
		behavior = {
			type = "request_pc_and_snack",
			moveSpeed = 13,
			snackChance = 0.35,
		},
	},
	{
		id = "delivery_abang",
		displayName = "Abang Delivery",
		class = "normal",
		spawnWeight = 25,
		modelName = "DeliveryAbang",
		animations = {
			idle = "rbxassetid://00000007",
			walk = "rbxassetid://00000008",
			emote = "rbxassetid://00000009",
		},
		behavior = {
			type = "drop_package_then_leave",
			moveSpeed = 14,
			staySeconds = 12,
		},
	},

	-- Anomaly NPC
	{
		id = "pocong_anomaly",
		displayName = "Pocong",
		class = "anomaly",
		spawnWeight = 28,
		modelName = "PocongAnomaly",
		animations = {
			idle = "rbxassetid://10000001",
			walk = "rbxassetid://10000002",
			emote = "rbxassetid://10000003",
		},
		behavior = {
			type = "hop_and_interrupt_power",
			moveSpeed = 10,
			jumpscareChance = 0.25,
		},
	},
	{
		id = "kuntilanak_anomaly",
		displayName = "Kuntilanak",
		class = "anomaly",
		spawnWeight = 24,
		modelName = "KuntilanakAnomaly",
		animations = {
			idle = "rbxassetid://10000004",
			walk = "rbxassetid://10000005",
			emote = "rbxassetid://10000006",
		},
		behavior = {
			type = "haunt_and_confuse_customers",
			moveSpeed = 11,
			terrorRadius = 20,
		},
	},
	{
		id = "suster_ngesot_anomaly",
		displayName = "Suster Ngesot",
		class = "anomaly",
		spawnWeight = 22,
		modelName = "SusterNgesotAnomaly",
		animations = {
			idle = "rbxassetid://10000007",
			walk = "rbxassetid://10000008",
			emote = "rbxassetid://10000009",
		},
		behavior = {
			type = "crawl_and_sabotage_pc",
			moveSpeed = 8,
			sabotageChance = 0.4,
		},
	},
	{
		id = "genderuwo_anomaly",
		displayName = "Genderuwo",
		class = "anomaly",
		spawnWeight = 26,
		modelName = "GenderuwoAnomaly",
		animations = {
			idle = "rbxassetid://10000010",
			walk = "rbxassetid://10000011",
			emote = "rbxassetid://10000012",
		},
		behavior = {
			type = "roar_and_force_minigame",
			moveSpeed = 13,
			pushForce = 42,
		},
	},

	-- Meme NPC
	{
		id = "tungtung_sahur",
		displayName = "TungTung Sahur",
		class = "meme",
		spawnWeight = 22,
		modelName = "TungTungSahur",
		animations = {
			idle = "rbxassetid://20000001",
			walk = "rbxassetid://20000002",
			emote = "rbxassetid://20000003",
		},
		behavior = {
			type = "bonk_player_for_event",
			moveSpeed = 15,
			bonkDamage = 0,
			setsFlag = "wasHitByTungTung",
		},
	},
	{
		id = "kelapa_sawit",
		displayName = "Kelapa Sawit",
		class = "meme",
		spawnWeight = 14,
		modelName = "KelapaSawit",
		animations = {
			idle = "rbxassetid://20000004",
			walk = "rbxassetid://20000005",
			emote = "rbxassetid://20000006",
		},
		behavior = {
			type = "spin_and_drop_bonus",
			moveSpeed = 9,
			bonusChance = 0.2,
		},
	},
	{
		id = "prabowo_meme",
		displayName = "Prabowo Meme",
		class = "meme",
		spawnWeight = 16,
		modelName = "PrabowoMeme",
		animations = {
			idle = "rbxassetid://20000007",
			walk = "rbxassetid://20000008",
			emote = "rbxassetid://20000009",
		},
		behavior = {
			type = "command_speech_buff",
			moveSpeed = 12,
			bonusMorale = 5,
		},
	},
	{
		id = "gibran_meme",
		displayName = "Gibran Meme",
		class = "meme",
		spawnWeight = 14,
		modelName = "GibranMeme",
		animations = {
			idle = "rbxassetid://20000010",
			walk = "rbxassetid://20000011",
			emote = "rbxassetid://20000012",
		},
		behavior = {
			type = "quick_visit_then_quote",
			moveSpeed = 14,
			staySeconds = 8,
		},
	},
	{
		id = "jokowi_meme",
		displayName = "Jokowi Meme",
		class = "meme",
		spawnWeight = 17,
		modelName = "JokowiMeme",
		animations = {
			idle = "rbxassetid://20000013",
			walk = "rbxassetid://20000014",
			emote = "rbxassetid://20000015",
		},
		behavior = {
			type = "inspection_event",
			moveSpeed = 11,
			inspectionScoreBoost = 10,
		},
	},
	{
		id = "mas_anies_meme",
		displayName = "Mas Anies",
		class = "meme",
		spawnWeight = 17,
		modelName = "MasAniesMeme",
		animations = {
			idle = "rbxassetid://20000016",
			walk = "rbxassetid://20000017",
			emote = "rbxassetid://20000018",
		},
		behavior = {
			type = "debate_and_redirect_queue",
			moveSpeed = 12,
			queueShuffleIntensity = 0.6,
		},
	},
}

return NPCBehaviorConfig
