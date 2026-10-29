"""Build deterministic original campaign resources. No network or external assets."""
import csv
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
strings = {}
with (ROOT / 'data/strings/ru.csv').open(encoding='utf-8-sig', newline='') as handle:
    original_strings = {row['key']: row for row in csv.DictReader(handle)}


def text(key, ru, en):
    strings[key] = (ru, en)
    return key


def write_json(name, data):
    path = ROOT / 'data/balance' / name
    path.parent.mkdir(exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


faction_rows = [
    ('woodland_freeholders', 'Вольные Земледельцы', 'Woodland Freeholders', 'Лесные общины теряют зерно из-за налётчиков.', 'Forest communities are losing grain to raiders.', 'cautious', 10),
    ('iron_guild', 'Гильдия Рудокопов', 'Iron Guild', 'Шахтёрам нужен безопасный путь для железных караванов.', 'The miners need a safe road for their iron caravans.', 'mercantile', 15),
    ('borderland_watch', 'Стража Пограничья', 'Borderland Watch', 'Старые гарнизоны разобщены после исчезновения маршала.', 'The old garrisons are divided after the marshal vanished.', 'honorable', 0),
    ('river_covenant', 'Речной Договор', 'River Covenant', 'Перевозчики удерживают переправы от вымогателей.', 'The ferrymen are defending their crossings from extortionists.', 'mercantile', 0),
    ('stone_circle', 'Каменный Круг', 'Stone Circle', 'Каменоломни больше не могут снабжать западные стены.', 'The quarries can no longer supply the western walls.', 'cautious', 5),
    ('marsh_keepers', 'Хранители Топей', 'Marsh Keepers', 'Лекари болот ищут исчезнувшие запасы целебного мха.', 'The marsh healers are searching for their missing medicinal moss.', 'isolationist', 0),
    ('sunfield_union', 'Союз Солнечных Полей', 'Sunfield Union', 'Разорённым мельницам нужна защита перед зимним голодом.', 'The ruined mills need protection before the winter famine.', 'honorable', 10),
    ('pass_clans', 'Кланы Перевала', 'Pass Clans', 'Кланы спорят о пошлинах пока крепость занята наёмниками.', 'The clans argue over tolls while mercenaries occupy the fortress.', 'pragmatic', 0),
]
factions = []
for index, (fid, ru, en, story_ru, story_en, personality, relation) in enumerate(faction_rows):
    name_key = text(f'faction.{fid}.name', ru, en)
    desc_key = text(f'faction.{fid}.desc', story_ru, story_en)
    factions.append(dict(id=fid, name=name_key, story=desc_key, relationship=relation, color=['#799554', '#7c8c9b', '#a56449', '#4a939b', '#9c916f', '#7e6b96', '#c2a253', '#86685c'][index]))
    resource = f'''[gd_resource type="Resource" script_class="FactionData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/autoload/FactionData.gd" id="1"]
[resource]
script = ExtResource("1")
id = "{fid}"
name_key = "{name_key}"
desc_key = "{desc_key}"
personality_type = "{personality}"
military_power = {40 + index * 8}.0
relationship_to_player = {relation}.0
'''
    (ROOT / f'data/factions/{fid}.tres').write_text(resource, encoding='utf-8')

town_rows = [
    ('greenhaven', 'Тихая Сечь', 'Greenhaven', 0, -150, 0),
    ('ironford', 'Железный Брод', 'Ironford', 420, -340, 1),
    ('old_watch', 'Старая Застава', 'Old Watch', 770, -650, 2),
    ('reed_crossing', 'Камышовая Переправа', 'Reed Crossing', 1150, -250, 3),
    ('stonewell', 'Каменный Колодец', 'Stonewell', 1100, 350, 4),
    ('moss_hearth', 'Моховой Очаг', 'Moss Hearth', 500, 700, 5),
    ('sunmill', 'Солнечная Мельница', 'Sunmill', -150, 900, 6),
    ('high_pass', 'Верхний Перевал', 'High Pass', -700, 1200, 7),
    ('pine_rest', 'Сосновый Привал', 'Pine Rest', -450, -420, 0),
    ('copper_hollow', 'Медная Лощина', 'Copper Hollow', 900, -1200, 1),
    ('ash_bastion', 'Ясеневый Бастион', 'Ash Bastion', 1500, -1050, 2),
    ('willow_wharf', 'Ивовая Пристань', 'Willow Wharf', 1500, 900, 3),
    ('white_quarry', 'Белая Каменоломня', 'White Quarry', -950, 300, 4),
    ('winter_gate', 'Зимние Ворота', 'Winter Gate', -1400, 1500, 7),
]
towns = []
for tid, ru, en, x, z, faction_index in town_rows:
    towns.append(dict(id=tid, name=text('town.' + tid, ru, en), x=x, z=z, faction=factions[faction_index]['id'], danger=1 + faction_index // 2))

quests = []
stages = [
    ('visit', 'Голос общины', 'The Community Speaks', 'Найдите старосту: {town}. Выслушайте беду общины.', 'Find the reeve in {town} and hear the community\'s trouble.', 25),
    ('delivery', 'Обоз надежды', 'A Wagon of Hope', 'Передайте общине 20 еды, 10 дерева и 5 руды через старосту.', 'Deliver 20 food, 10 wood and 5 ore through the reeve.', 50),
    ('camp', 'Дорога без разбойников', 'A Road Without Raiders', 'Очистите лагерь к востоку от поселения. Его защитники сражаются в мире.', 'Clear the camp east of town. Its defenders fight in the actual world.', 100),
    ('trust', 'Цена доверия', 'The Price of Trust', 'Добейтесь отношения 60 или победите гарнизон. Помощь и дары укрепляют доверие.', 'Reach 60 trust or defeat the garrison. Aid and gifts build trust.', 50),
    ('oath', 'Клятва у очага', 'An Oath at the Hearth', 'Заключите союз в Совете [F] или захватите укрепление через старосту.', 'Sign an alliance in the Council [F], or seize the stronghold through the reeve.', 75),
    ('report', 'Место за общим столом', 'A Seat at the Council', 'Вернитесь к старосте после союза или завоевания. Откроется дорога к следующей общине.', 'Return to the reeve after alliance or conquest. The road to the next community will open.', 100),
]
for i, faction in enumerate(factions):
    for j, (kind, ru, en, desc_ru, desc_en, reward) in enumerate(stages):
        qid = f'arc_{i + 1:02}_{j + 1:02}'
        town = towns[i]
        quests.append(dict(id=qid, kind=kind, faction=faction['id'], town=town['id'], requires=[] if j == 0 else [f'arc_{i + 1:02}_{j:02}'],
                           title=text('quest.' + qid + '.title', f'{ru}: {faction_rows[i][1]}', f'{en}: {faction_rows[i][2]}'),
                           description=text('quest.' + qid + '.desc', desc_ru.format(town=town_rows[i][1]), desc_en.format(town=town_rows[i][2])), reward=reward))
for i, faction in enumerate(factions):
    qid = 'survey_' + faction['id']
    quests.append(dict(id=qid, kind='survey', faction=faction['id'], requires=[], reward=45,
        title=text('quest.' + qid + '.title', 'Следы прошлого: ' + faction_rows[i][1], 'Traces of the Past: ' + faction_rows[i][2]),
        description=text('quest.' + qid + '.desc', 'Осмотрите святилище к западу от поселения. Найденные припасы помогут общине.', 'Explore the shrine west of town. Its supplies will help the community.')))
companion_rows = [
    ('warrior_shield', 'Рада', 'Rada', 0, 'Верните щит заставы из разбойничьего лагеря.', 'Recover the watch shield from the raider camp.'),
    ('archer_scout', 'Терен', 'Teren', 2, 'Откройте три дорожные точки и очистите лагерь Стражи.', 'Open three road points and clear the Watch camp.'),
    ('healer_alchemist', 'Мира', 'Mira', 5, 'Сварите три зелья и помогите Хранителям Топей.', 'Brew three potions and aid the Marsh Keepers.'),
    ('mercenary_commander', 'Освин', 'Oswin', 7, 'Соберите пять бойцов и освободите Перевал.', 'Recruit five soldiers and free the Pass.'),
]
for cid, ru, en, region, objective_ru, objective_en in companion_rows:
    qid = 'companion_' + cid
    quests.append(dict(id=qid, kind='companion', companion=cid, faction=factions[region]['id'], requires=[], reward=100,
        title=text('quest.' + qid + '.title', 'Личная клятва: ' + ru, 'A Personal Oath: ' + en),
        description=text('quest.' + qid + '.desc', objective_ru, objective_en)))
    text('companion.' + cid + '.name', ru, en)

points = []
for i, faction in enumerate(factions):
    town = towns[i]
    for j, (kind, dx, dz) in enumerate([('camp', 85, 15), ('shrine', -70, -20), ('cache', 30, 90), ('ruins', -75, 90), ('mine', 90, -80)]):
        points.append(dict(id=f'{faction["id"]}_{kind}', kind=kind, faction=faction['id'], x=town['x'] + dx, z=town['z'] + dz, danger=town['danger'], boss=i in (2, 5, 7) and kind == 'camp'))

write_json('campaign.json', dict(seed=74109, world_size=4000, factions=factions, towns=towns, quests=quests, points=points,
    delivery_cost=dict(food=20, wood=10, ore=5), travel_cost=dict(food=3, gold=5),
    difficulties=[dict(id='story', enemy_health=0.65, enemy_damage=0.65), dict(id='normal', enemy_health=1, enemy_damage=1), dict(id='hard', enemy_health=1.25, enemy_damage=1.2), dict(id='expert', enemy_health=1.55, enemy_damage=1.5)]))

buildings = []
building_rows = [
    ('farm', 'Поле', 'Farm', {'wood': 25, 'gold': 30}, {'food': 8}),
    ('housing', 'Жилой дом', 'Housing', {'wood': 30, 'stone': 10, 'gold': 40}, {'housing': 10}),
    ('infirmary', 'Лазарет', 'Infirmary', {'wood': 35, 'ore': 10, 'gold': 65}, {'health': 2}),
    ('well', 'Колодец', 'Well', {'stone': 20, 'gold': 25}, {'health': 1, 'happiness': 1}),
    ('market', 'Торговый двор', 'Market', {'wood': 40, 'stone': 15, 'gold': 75}, {'gold': 10}),
    ('sawmill', 'Лесопилка', 'Sawmill', {'wood': 30, 'ore': 10, 'gold': 50}, {'wood': 6}),
    ('quarry', 'Каменоломня', 'Quarry', {'wood': 20, 'ore': 15, 'gold': 45}, {'stone': 5}),
    ('forge', 'Кузница', 'Forge', {'stone': 25, 'ore': 20, 'gold': 80}, {'ore': 4}),
    ('barracks', 'Казармы', 'Barracks', {'wood': 40, 'stone': 30, 'gold': 100}, {'housing': 5}),
    ('hall', 'Общий зал', 'Council Hall', {'wood': 60, 'stone': 30, 'gold': 120}, {'happiness': 2}),
]
for bid, ru, en, cost, effects in building_rows:
    buildings.append(dict(id=bid, name=text('building.' + bid, ru, en), cost=cost, daily=effects, max_level=3))
write_json('buildings.json', buildings)

# Four material tiers supplement the fourteen original base equipment types.
gear = []
qualities = [('hardened', 'Закалённый', 'Hardened', 1.25), ('tempered', 'Усиленный', 'Tempered', 1.55), ('guild', 'Гильдейский', 'Guild', 1.9), ('master', 'Мастерский', 'Masterwork', 2.3)]
for category in ('weapons', 'armors'):
    originals = sorted(p for p in (ROOT / 'data' / category).glob('*.tres') if not any(p.stem.endswith('_' + q[0]) for q in qualities))
    for base in originals:
        source = base.read_text(encoding='utf-8')
        original_key = re.search(r'name_key = "([^"]+)"', source).group(1)
        for level, (suffix, ru, en, multiplier) in enumerate(qualities):
            gid = base.stem + '_' + suffix
            rewritten = re.sub(r'(?m)^id = .*$', f'id = "{gid}"', source)
            rewritten = re.sub(r'(?m)^name_key = .*$', f'name_key = "item.{gid}.name"', rewritten)
            rewritten = re.sub(r'(?m)^desc_key = .*$', f'desc_key = "item.{gid}.desc"', rewritten)
            for stat in ('damage', 'defense', 'durability'):
                rewritten = re.sub(rf'(?m)^{stat} = ([\d.]+)$', lambda m: f'{stat} = {float(m[1]) * multiplier:.2f}', rewritten)
            rewritten = re.sub(r'(?m)^rarity = .*$', f'rarity = "{["uncommon", "rare", "epic", "legendary"][level]}"', rewritten)
            destination = ROOT / 'data' / category / (gid + '.tres')
            destination.write_text(rewritten, encoding='utf-8')
            original_name = original_strings.get(original_key, {'ru': base.stem, 'en': base.stem})
            ending = 'ая' if base.stem in ['chainmail', 'mace'] else 'ое' if base.stem == 'iron_spear' else ('ие' if ru.endswith('ий') else 'ые') if base.stem in ['plate_armor', 'leather_boots', 'iron_greaves'] else ru[-2:]
            adjective = ru[:-2] + ending
            text('item.' + gid + '.name', adjective + ' ' + original_name['ru'][0].lower() + original_name['ru'][1:], en + ' ' + original_name['en'])
            text('item.' + gid + '.desc', 'Работа местных кузнецов. Улучшенные защита или урон и ресурс прочности.', 'Local smithwork with improved protection or damage and durability.')
            gear.append(dict(id=gid, path='res://' + destination.relative_to(ROOT).as_posix(), price=(level + 1) * 65 + 25, tier=level + 1))
write_json('equipment.json', gear)
crafts = []
for i, item in enumerate(gear[::4][:12]):
    crafts.append(dict(id=item['id'], result=item['path'], cost=dict(ore=8 + i * 2, wood=4 + i, gold=15 + i * 5)))
write_json('crafting.json', crafts)

ingredients = [('ember_bloom', 'Жароцвет', 'Ember Bloom'), ('river_mint', 'Речная мята', 'River Mint'), ('stone_moss', 'Каменный мох', 'Stone Moss'), ('marsh_root', 'Болотный корень', 'Marsh Root')]
for iid, ru, en in ingredients:
    text('item.' + iid + '.name', ru, en)
    text('item.' + iid + '.desc', 'Сырьё для местных алхимических настоев.', 'An ingredient for local alchemical infusions.')
    path = ROOT / 'data/potions' / (iid + '.tres')
    path.write_text(f'''[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/autoload/ItemData.gd" id="1"]
[resource]
script = ExtResource("1")
id = "{iid}"
name_key = "item.{iid}.name"
desc_key = "item.{iid}.desc"
weight = 0.1
type = "misc"
''', encoding='utf-8')

recipes = [dict(id='health_potion_recipe', result='res://data/potions/health_potion.tres', ingredients={'healing_herb': 2})]
potion_types = [('vitality', 'здоровья', 'Vitality', 'heal_amount', 25), ('vigor', 'бодрости', 'Vigor', 'stamina_amount', 25), ('might', 'силы', 'Might', 'damage_multiplier', 0.12), ('barkskin', 'каменной кожи', 'Barkskin', 'defense_bonus', 12), ('swift', 'попутного ветра', 'Tailwind', 'movement_multiplier', 0.08)]
for effect_index, (pid, ru, en, field, amount) in enumerate(potion_types):
    for tier in range(1, 5):
        iid = f'{pid}_{tier}'
        potency_ru = ['Слабый настой', 'Настой', 'Концентрат', 'Эликсир'][tier - 1]
        potency_en = ['Weak', 'Brewed', 'Concentrated', 'Grand'][tier - 1]
        text('item.' + iid + '.name', potency_ru + ' ' + ru, potency_en + ' ' + en)
        value = 1 + amount * tier if 'multiplier' in field else amount * tier
        text('item.' + iid + '.desc', f'Эффект: {ru}. Сила {value:g}; длительность {20 + tier * 10} сек. Усиления одного типа заменяют друг друга.', f'{en} effect. Potency {value:g}; duration {20 + tier * 10} seconds. Effects of the same type replace one another.')
        resource = f'''[gd_resource type="Resource" script_class="PotionData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/autoload/PotionData.gd" id="1"]
[resource]
script = ExtResource("1")
id = "{iid}"
name_key = "item.{iid}.name"
desc_key = "item.{iid}.desc"
heal_amount = 0.0
{field} = {value:.2f}
effect_duration = {20 + tier * 10}.0
'''
        # Avoid duplicate heal_amount assignments in health resources.
        if field == 'heal_amount': resource = resource.replace('heal_amount = 0.0\n', '')
        (ROOT / 'data/potions' / (iid + '.tres')).write_text(resource, encoding='utf-8')
        ingredient = ingredients[effect_index % len(ingredients)][0]
        recipes.append(dict(id=iid + '_recipe', result='res://data/potions/' + iid + '.tres', ingredients={'healing_herb': tier, ingredient: tier}))
for original in ['stamina_potion', 'strength_potion', 'health_potion_large', 'antidote_potion']:
    recipes.append(dict(id=original + '_recipe', result='res://data/potions/' + original + '.tres', ingredients={'healing_herb': 3, 'marsh_root': 1}))
write_json('alchemy.json', recipes)

for filename in ('ru.csv', 'en.csv'):
    path = ROOT / 'data/strings' / filename
    with path.open(encoding='utf-8-sig', newline='') as handle:
        existing = {row['key']: row for row in csv.DictReader(handle)}
    for key, (ru, en) in strings.items():
        existing[key] = dict(key=key, ru=ru, en=en)
    with path.open('w', encoding='utf-8', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=['key', 'ru', 'en'])
        writer.writeheader()
        writer.writerows(existing.values())
print(f'Campaign: {len(factions)} factions, {len(towns)} towns, {len(quests)} quests, {len(points)} points, {len(gear) + 14} gear, {len(crafts)} blueprints')
from compile_localization import compile_catalog
compile_catalog(ROOT)
