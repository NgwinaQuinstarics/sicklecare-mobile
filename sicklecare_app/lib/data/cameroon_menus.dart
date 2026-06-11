/// Healthy Cameroonian daily menus. The week's plan rotates through this list
/// (so it renews every week), and users can override any day (persisted).
class MealItem {
  final String en;
  final String fr;
  const MealItem(this.en, this.fr);
  String t(bool fr) => fr ? this.fr : en;
}

class DayMenu {
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem dinner;
  final MealItem snack;
  const DayMenu(this.breakfast, this.lunch, this.dinner, this.snack);
}

const kCameroonMenus = <DayMenu>[
  DayMenu(
    MealItem('Millet porridge + banana', 'Bouillie de mil + banane'),
    MealItem('Brown rice + okra (gombo) sauce + grilled fish',
        'Riz complet + sauce gombo + poisson braisé'),
    MealItem('Sautéed greens (folong) + sweet potato',
        'Légumes (folong) sautés + patate douce'),
    MealItem('Orange + a handful of groundnuts',
        "Orange + une poignée d'arachides"),
  ),
  DayMenu(
    MealItem('Whole-grain bread + egg + avocado',
        'Pain complet + œuf + avocat'),
    MealItem('Light ndolé + ripe plantain', 'Ndolé léger + plantain mûr'),
    MealItem('Vegetable soup + yam', 'Soupe de légumes + igname'),
    MealItem('Papaya + water', 'Papaye + eau'),
  ),
  DayMenu(
    MealItem('Maize porridge + milk', 'Bouillie de maïs + lait'),
    MealItem('Eru + water-fufu (moderate portion)',
        'Eru + couscous de manioc (portion modérée)'),
    MealItem('Steamed fish + green beans', 'Poisson vapeur + haricots verts'),
    MealItem('Guava + water', 'Goyave + eau'),
  ),
  DayMenu(
    MealItem('Oats + mango', 'Flocons d’avoine + mangue'),
    MealItem('Beans (koki) + ripe plantain', 'Haricots (koki) + plantain mûr'),
    MealItem('Grilled chicken + sautéed vegetables',
        'Poulet grillé + légumes sautés'),
    MealItem('Watermelon', 'Pastèque'),
  ),
  DayMenu(
    MealItem('Sweet potato + boiled egg', 'Patate douce + œuf dur'),
    MealItem('Vegetable jollof rice + fish', 'Riz aux légumes + poisson'),
    MealItem('Pumpkin-leaf (kontomire) stew + cocoyam',
        'Sauce de feuilles + taro'),
    MealItem('Pineapple + groundnuts', 'Ananas + arachides'),
  ),
  DayMenu(
    MealItem('Pap (fermented maize) + groundnut paste',
        'Pap (bouillie de maïs) + pâte d’arachide'),
    MealItem('Okra soup + brown rice + fish',
        'Sauce gombo + riz complet + poisson'),
    MealItem('Bean porridge + plantain', 'Bouillie de haricots + plantain'),
    MealItem('Banana + water', 'Banane + eau'),
  ),
  DayMenu(
    MealItem('Whole-grain bread + avocado + orange juice',
        'Pain complet + avocat + jus d’orange'),
    MealItem('Vegetable couscous + grilled fish',
        'Couscous de légumes + poisson grillé'),
    MealItem('Light pepper-soup (fish) + yam',
        'Pepper-soup léger (poisson) + igname'),
    MealItem('Mango + water', 'Mangue + eau'),
  ),
  DayMenu(
    MealItem('Boiled plantain + beans', 'Plantain bouilli + haricots'),
    MealItem('Spinach stew + brown rice', 'Sauce d’épinards + riz complet'),
    MealItem('Grilled fish + steamed vegetables',
        'Poisson grillé + légumes vapeur'),
    MealItem('Pawpaw (papaya) + groundnuts', 'Papaye + arachides'),
  ),
  DayMenu(
    MealItem('Millet porridge + dates', 'Bouillie de mil + dattes'),
    MealItem('Bobolo + smoked fish + greens',
        'Bobolo + poisson fumé + légumes'),
    MealItem('Vegetable omelette + sweet potato',
        'Omelette aux légumes + patate douce'),
    MealItem('Orange + water', 'Orange + eau'),
  ),
  DayMenu(
    MealItem('Oats + banana + groundnuts',
        'Flocons d’avoine + banane + arachides'),
    MealItem('Light ndolé + boiled plantain', 'Ndolé léger + plantain bouilli'),
    MealItem('Lentil/bean stew + rice', 'Ragoût de lentilles/haricots + riz'),
    MealItem('Guava', 'Goyave'),
  ),
  DayMenu(
    MealItem('Sweet potato porridge', 'Bouillie de patate douce'),
    MealItem('Okra + cocoyam + fish', 'Gombo + taro + poisson'),
    MealItem('Grilled chicken + green salad',
        'Poulet grillé + salade verte'),
    MealItem('Watermelon + water', 'Pastèque + eau'),
  ),
  DayMenu(
    MealItem('Pap + boiled egg', 'Pap + œuf dur'),
    MealItem('Vegetable fried rice + fish', 'Riz sauté aux légumes + poisson'),
    MealItem('Bitterleaf soup + water-fufu (moderate)',
        'Sauce de ndolé/bitterleaf + couscous (modéré)'),
    MealItem('Pineapple', 'Ananas'),
  ),
  DayMenu(
    MealItem('Whole-grain bread + peanut butter + banana',
        'Pain complet + pâte d’arachide + banane'),
    MealItem('Beans + ripe plantain + greens',
        'Haricots + plantain mûr + légumes'),
    MealItem('Fish pepper-soup + yam', 'Pepper-soup de poisson + igname'),
    MealItem('Orange', 'Orange'),
  ),
  DayMenu(
    MealItem('Maize & groundnut porridge', 'Bouillie maïs-arachide'),
    MealItem('Brown rice + vegetable sauce + grilled fish',
        'Riz complet + sauce légumes + poisson grillé'),
    MealItem('Sautéed folong + sweet potato',
        'Folong sauté + patate douce'),
    MealItem('Papaya + water', 'Papaye + eau'),
  ),
];
