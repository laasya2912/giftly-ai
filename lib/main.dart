
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = 'http://127.0.0.1:8000';

const Color primaryPink = Color(0xFFE85D9E);
const Color deepPurple = Color(0xFF7357D8);
const Color palePink = Color(0xFFFFF1F7);
const Color palePurple = Color(0xFFF2EEFF);

void main() {
  runApp(const GiftlyApp());
}

class GiftlyApp extends StatelessWidget {
  const GiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giftly AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryPink),
        scaffoldBackgroundColor: const Color(0xFFFFFAFD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFAFD),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFEADDE7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFEADDE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryPink, width: 1.5),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// GIFT MODEL
// -----------------------------------------------------------------------------

class GiftItem {
  final String name;
  final String category;
  final int price;
  final String description;
  final String reason;
  final String emoji;

  const GiftItem({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.reason,
    required this.emoji,
  });

  factory GiftItem.fromJson(Map<String, dynamic> json) {
  final rawPrice = json['price'] ??
      json['estimated_price'] ??
      json['price_range'] ??
      0;

  int price = 0;

  if (rawPrice is num) {
    price = rawPrice.round();
  } else {
    final matches = RegExp(r'\d[\d,]*')
        .allMatches(rawPrice.toString())
        .map((m) => int.tryParse(
              m.group(0)!.replaceAll(',', ''),
            ))
        .whereType<int>()
        .toList();

    // Use the upper end of a range, e.g. ₹500–₹1,000 => ₹1,000.
    if (matches.isNotEmpty) {
      price = matches.last;
    }
  }

  return GiftItem(
    name: (json['name'] ??
            json['gift_name'] ??
            json['title'] ??
            'Personalised Gift')
        .toString(),
    category: (json['category'] ?? 'Other').toString(),
    price: price,
    description: (json['description'] ??
            json['reasoning'] ??
            'A thoughtful gift choice.')
        .toString(),
    reason: (json['reason'] ??
            json['reasoning'] ??
            json['why_recommended'] ??
            'A lovely option for your recipient.')
        .toString(),
    emoji: (json['emoji'] ?? '🎁').toString(),
  );
}

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'reason': reason,
        'emoji': emoji,
      };

  String get id => name.trim().toLowerCase();
}

// -----------------------------------------------------------------------------
// CATALOGUE: 20 DIFFERENT GIFTS IN EACH CATEGORY
// -----------------------------------------------------------------------------

const Map<String, List<List<String>>> giftData = {
  'Books': [
    ['Mystery Thriller Novel', '📚', 'An exciting page-turning mystery.'],
    ['Romantic Fiction Novel', '💗', 'A heartfelt romantic story.'],
    ['Fantasy Adventure Book', '🐉', 'A magical world of adventure.'],
    ['Science Fiction Novel', '🚀', 'A journey into the future.'],
    ['Self-Improvement Book', '🌱', 'Ideas for personal growth.'],
    ['Motivational Biography', '⭐', 'An inspiring real-life story.'],
    ['Poetry Collection', '📝', 'Beautiful poems and reflections.'],
    ['Classic Literature Edition', '📖', 'A timeless literary classic.'],
    ['Personal Finance Book', '💰', 'Practical money-management lessons.'],
    ['Psychology Book', '🧠', 'Explore human behaviour and thinking.'],
    ['Travel Photography Book', '🌍', 'Beautiful destinations and photographs.'],
    ['Cookbook for Beginners', '🍳', 'Easy recipes to try at home.'],
    ['Art and Drawing Guide', '🎨', 'Creative exercises and techniques.'],
    ['Productivity Planner Book', '📅', 'Organise goals and daily tasks.'],
    ['History Illustrated Book', '🏛️', 'Discover historical events and people.'],
    ['Science for Curious Minds', '🔬', 'Fun explanations of scientific ideas.'],
    ['Language Learning Book', '🗣️', 'Learn words and everyday expressions.'],
    ['Graphic Novel', '🦸', 'A story told through illustrations.'],
    ['Gardening Guide', '🪴', 'Grow plants and care for a garden.'],
    ['Journal and Writing Book', '✍️', 'A space for thoughts and stories.'],
  ],
  'Toys': [
    ['Building Block Set', '🧱', 'Build creative structures and models.'],
    ['Remote Control Car', '🏎️', 'A fun car for racing games.'],
    ['Jigsaw Puzzle', '🧩', 'A relaxing problem-solving activity.'],
    ['Board Game', '🎲', 'Enjoy game nights with family.'],
    ['Soft Teddy Bear', '🧸', 'A cute and cuddly companion.'],
    ['Dinosaur Figure Set', '🦖', 'A fun prehistoric collection.'],
    ['Art and Craft Kit', '✂️', 'Make colourful creative projects.'],
    ['Toy Train Set', '🚂', 'Create a miniature railway.'],
    ['Mini Basketball Hoop', '🏀', 'Practise shooting indoors.'],
    ['Kids Science Experiment Kit', '🧪', 'Explore simple science experiments.'],
    ['Magnetic Drawing Board', '✏️', 'Draw and erase again and again.'],
    ['Doll House Set', '🏠', 'Create imaginative miniature stories.'],
    ['Robot Building Kit', '🤖', 'Build a toy robot.'],
    ['Kite Flying Kit', '🪁', 'Enjoy a breezy outdoor activity.'],
    ['Watercolour Painting Set', '🖌️', 'Explore colours and painting.'],
    ['Wooden Shape Sorter', '🔷', 'Learn shapes through play.'],
    ['Foam Dart Toy', '🎯', 'Enjoy target games safely.'],
    ['Plush Animal Set', '🐼', 'A collection of soft animal toys.'],
    ['LEGO-Style Vehicle Kit', '🚙', 'Build a miniature vehicle.'],
    ['Memory Matching Game', '🃏', 'Practise memory while playing.'],
  ],
  'Fitness': [
    ['Adjustable Dumbbells', '🏋️', 'A compact strength-training option.'],
    ['Yoga Mat', '🧘', 'Comfortable support for yoga sessions.'],
    ['Resistance Band Set', '💪', 'Versatile bands for home workouts.'],
    ['Stainless Steel Shaker', '🥤', 'A convenient workout drink bottle.'],
    ['Digital Skipping Rope', '🪢', 'A simple cardio workout tool.'],
    ['Sports Water Bottle', '🚰', 'Stay hydrated during exercise.'],
    ['Gym Duffle Bag', '🎒', 'Carry workout essentials conveniently.'],
    ['Fitness Gloves', '🧤', 'Comfortable grip for weight training.'],
    ['Foam Roller', '🌀', 'Useful for post-workout mobility routines.'],
    ['Push-Up Bars', '🤸', 'Add variety to upper-body workouts.'],
    ['Yoga Block Pair', '🧘', 'Extra support for yoga poses.'],
    ['Ankle Weights', '🦵', 'Add resistance to selected exercises.'],
    ['Running Belt', '🏃', 'Carry small essentials while running.'],
    ['Sweat-Wicking Sports Towel', '🏅', 'A practical gym essential.'],
    ['Exercise Mat', '🤸', 'A cushioned surface for floor exercises.'],
    ['Massage Ball', '⚽', 'Targeted muscle massage after activity.'],
    ['Agility Ladder', '🏃', 'Practise footwork and coordination.'],
    ['Cycling Gloves', '🚴', 'Comfort and grip for cycling.'],
    ['Workout Journal', '📒', 'Track workouts and fitness goals.'],
    ['Insulated Gym Bottle', '🧊', 'Keep drinks cool during training.'],
  ],
  'Fashion': [
    ['Classic Graphic T-Shirt', '👕', 'An easy everyday wardrobe addition.'],
    ['Oversized Hoodie', '🧥', 'A cosy casual clothing option.'],
    ['Printed Scarf', '🧣', 'Add colour to an outfit.'],
    ['Minimalist Wristwatch', '⌚', 'A timeless everyday accessory.'],
    ['Casual Baseball Cap', '🧢', 'A relaxed finishing touch.'],
    ['Denim Jacket', '🧥', 'A versatile layering piece.'],
    ['Printed Socks Gift Set', '🧦', 'Colourful socks for daily wear.'],
    ['Canvas Sneakers', '👟', 'Casual footwear for everyday use.'],
    ['Elegant Clutch Bag', '👛', 'A compact accessory for outings.'],
    ['Leather-Style Wallet', '👝', 'A useful everyday essential.'],
    ['Minimalist Belt', '🪢', 'A practical wardrobe accessory.'],
    ['Knit Beanie', '🧶', 'A soft and casual winter accessory.'],
    ['Statement Earrings', '✨', 'Add sparkle to an outfit.'],
    ['Pendant Necklace', '📿', 'A simple piece of jewellery.'],
    ['Everyday Tote Bag', '👜', 'Carry books or daily essentials.'],
    ['Polarised Sunglasses', '🕶️', 'A stylish accessory for sunny days.'],
    ['Printed Kurta', '👘', 'A colourful ethnic-wear option.'],
    ['Comfortable Joggers', '👖', 'Relaxed trousers for casual wear.'],
    ['Hair Accessories Set', '🎀', 'Clips and bands for styling.'],
    ['Personalised Name Bracelet', '💎', 'A customised accessory with a name.'],
  ],
  'Tech': [
    ['Wireless Earbuds', '🎧', 'Listen to music without cables.'],
    ['Bluetooth Speaker', '🔊', 'Enjoy music at home or outdoors.'],
    ['Power Bank', '🔋', 'Extra battery power while travelling.'],
    ['Wireless Mouse', '🖱️', 'A useful computer accessory.'],
    ['Mechanical Keyboard', '⌨️', 'A satisfying typing experience.'],
    ['Laptop Stand', '💻', 'Raise a laptop for a better setup.'],
    ['Phone Tripod', '📱', 'Helpful for photos and video calls.'],
    ['Smart LED Desk Lamp', '💡', 'Adjustable lighting for a desk.'],
    ['USB-C Hub', '🔌', 'Add ports to a compatible laptop.'],
    ['Phone Stand', '📲', 'Hands-free viewing on a desk.'],
    ['Mini Projector', '📽️', 'Create a home movie setup.'],
    ['Portable SSD', '💾', 'Store and carry digital files.'],
    ['Smart Plug', '🔌', 'Control compatible appliances conveniently.'],
    ['Gaming Controller', '🎮', 'An accessory for compatible games.'],
    ['Webcam', '📷', 'Improve video calls and streaming.'],
    ['Digital Alarm Clock', '⏰', 'A clear bedside time display.'],
    ['E-Reader', '📖', 'Carry a digital library.'],
    ['Cable Organiser Kit', '🧵', 'Keep charging cables tidy.'],
    ['Mini Photo Printer', '🖨️', 'Print compatible photos at home.'],
    ['Laptop Sleeve', '💼', 'Help protect a laptop while travelling.'],
  ],
  'Beauty': [
    ['Skincare Gift Set', '🧴', 'A coordinated skincare collection.'],
    ['Lip Balm Collection', '💄', 'A handy set for lip care.'],
    ['Perfume Gift Set', '🌸', 'A fragrance gift for special occasions.'],
    ['Makeup Brush Set', '🖌️', 'Brushes for makeup application.'],
    ['Nail Polish Collection', '💅', 'A range of nail colours.'],
    ['Compact Makeup Mirror', '🪞', 'A portable mirror for touch-ups.'],
    ['Hair Styling Brush', '💇', 'A useful everyday hair tool.'],
    ['Bath and Body Set', '🛁', 'A relaxing self-care collection.'],
    ['Satin Sleep Mask', '😴', 'A soft accessory for bedtime.'],
    ['Hand Cream Set', '🤲', 'Moisturising creams for daily care.'],
    ['Face Mask Pack', '🧖', 'A collection for a self-care routine.'],
    ['Cosmetic Organiser', '🧺', 'Keep beauty products organised.'],
    ['Hair Scrunchie Set', '🎀', 'Colourful accessories for hairstyles.'],
    ['Travel Toiletry Pouch', '🧳', 'Organise personal-care essentials.'],
    ['Body Mist Collection', '🌷', 'Light fragrance options for daily wear.'],
    ['Electric Facial Cleansing Brush', '🫧', 'A tool for a cleansing routine.'],
    ['Manicure Kit', '💅', 'Tools for basic nail care.'],
    ['Silk-Style Pillowcase', '🛏️', 'A smooth and comfortable pillow cover.'],
    ['Aroma Diffuser', '🌿', 'Create a pleasant room atmosphere.'],
    ['Personalised Makeup Pouch', '👝', 'A customised pouch for cosmetics.'],
  ],
  'Home Decor': [
    ['Aromatic Candle Set', '🕯️', 'Add fragrance and ambience.'],
    ['Indoor Plant Pot', '🪴', 'Display a favourite indoor plant.'],
    ['Photo Frame', '🖼️', 'Showcase a favourite memory.'],
    ['Decorative Table Lamp', '💡', 'Add warm lighting to a room.'],
    ['Ceramic Coffee Mug', '☕', 'A useful everyday mug.'],
    ['Decorative Cushion Cover', '🛋️', 'Refresh a sofa or bed.'],
    ['Wall Art Print', '🎨', 'Add personality to a wall.'],
    ['Mini Desk Plant', '🌱', 'A small green desk companion.'],
    ['Fairy String Lights', '✨', 'Create a cosy lighting effect.'],
    ['Decorative Vase', '🏺', 'Display flowers or stand alone.'],
    ['Scented Wax Melts', '🌼', 'A fragrance option for compatible warmers.'],
    ['Tabletop Photo Stand', '📸', 'Display a favourite picture.'],
    ['Ceramic Planter Set', '🌿', 'A coordinated set for plants.'],
    ['Handmade Coaster Set', '🍵', 'Protect surfaces from drink marks.'],
    ['Decorative Wall Clock', '🕰️', 'A functional wall decoration.'],
    ['Soft Throw Blanket', '🧶', 'A cosy accent for a sofa.'],
    ['Jewellery Tray', '💍', 'Keep small accessories in one place.'],
    ['Decorative Bookends', '📚', 'Keep books upright on a shelf.'],
    ['Minimalist Desk Organiser', '🗂️', 'Tidy stationery and small items.'],
    ['Personalised Name Plate', '🏷️', 'Custom decor for a room or desk.'],
  ],
  'Accessories': [
    ['Minimalist Keychain', '🔑', 'A small everyday personalised gift.'],
    ['Travel Passport Holder', '🛂', 'Organise travel documents.'],
    ['Card Holder', '💳', 'Carry essential cards neatly.'],
    ['Reusable Shopping Tote', '🛍️', 'A practical bag for errands.'],
    ['Insulated Travel Mug', '☕', 'Carry a favourite hot drink.'],
    ['Compact Umbrella', '☂️', 'A useful rainy-day essential.'],
    ['Travel Jewellery Case', '💍', 'Store jewellery while travelling.'],
    ['Luggage Tag Set', '🧳', 'Identify bags more easily.'],
    ['Personalised Photo Keyring', '📸', 'Keep a favourite photo close.'],
    ['Desk Calendar', '📅', 'Plan dates and appointments.'],
    ['Premium Pen Set', '🖊️', 'A useful gift for writing.'],
    ['Notebook and Pen Set', '📓', 'For notes, plans, and ideas.'],
    ['Reusable Coffee Cup', '🥤', 'A cup for takeaway drinks.'],
    ['Compact Jewellery Box', '📦', 'Store rings and small accessories.'],
    ['Foldable Phone Holder', '📱', 'A portable phone stand.'],
    ['Travel Packing Cubes', '🧳', 'Organise clothes inside luggage.'],
    ['Custom Name Mug', '☕', 'A mug printed with a name.'],
    ['Minimalist Pendant', '📿', 'A simple accessory for daily wear.'],
    ['Printed Bookmark Set', '🔖', 'A thoughtful extra for readers.'],
    ['Personalised Gift Box', '🎁', 'A curated presentation for a gift.'],
  ],
};

final List<GiftItem> giftCatalogue = [
  for (final entry in giftData.entries)
    for (int i = 0; i < entry.value.length; i++)
      GiftItem(
        name: entry.value[i][0],
        category: entry.key,
        emoji: entry.value[i][1],
        description: entry.value[i][2],
        reason: 'A thoughtful ${entry.key.toLowerCase()} gift idea.',
        price: 299 + ((i * 173 + entry.key.length * 41) % 2700),
      ),
];

// -----------------------------------------------------------------------------
// AUTHENTICATION
// -----------------------------------------------------------------------------

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool loading = false;
  bool obscure = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (!isLogin && name.isEmpty) {
      showMessage(context, 'Please enter your name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      showMessage(context, 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      showMessage(context, 'Password must contain at least 8 characters.');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/${isLogin ? 'login' : 'register'}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (!isLogin) 'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userData =
            (data['user'] is Map ? data['user'] : data).cast<String, dynamic>();

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GiftHomePage(
              userId: userData['id'].toString(),
              userName: (userData['name'] ?? name).toString(),
              email: (userData['email'] ?? email).toString(),
            ),
          ),
        );
      } else {
        showMessage(
          context,
          (data['detail'] ?? data['message'] ?? 'Authentication failed.')
              .toString(),
        );
      }
    } catch (_) {
      showMessage(
        context,
        'Cannot connect to backend. Start your FastAPI server first.',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [palePink, Color(0xFFF9F5FF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryPink, deepPurple],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          size: 43,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Giftly AI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: deepPurple,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Make every gift feel special.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 25),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Login')),
                          ButtonSegment(value: false, label: Text('Register')),
                        ],
                        selected: {isLogin},
                        onSelectionChanged: (selection) {
                          setState(() => isLogin = selection.first);
                        },
                      ),
                      const SizedBox(height: 20),
                      if (!isLogin) ...[
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 51,
                        child: FilledButton(
                          onPressed: loading ? null : submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isLogin ? 'Login' : 'Create account',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HOME, AI RECOMMENDATIONS, SAVED GIFTS AND EXPLORE SCREEN
// -----------------------------------------------------------------------------

class GiftHomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String email;

  const GiftHomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.email,
  });

  @override
  State<GiftHomePage> createState() => _GiftHomePageState();
}

class _GiftHomePageState extends State<GiftHomePage> {
  final recipientController = TextEditingController();
  final interestsController = TextEditingController();
  final budgetController = TextEditingController();
  final searchController = TextEditingController();

  String occasion = 'Birthday';
  String relationship = 'Friend';
  String currency = 'INR';

  bool generating = false;
  bool loadingSaved = false;
  String selectedCategory = 'All';
  String activeTab = 'Home';

  List<GiftItem> recommendations = [];
  List<GiftItem> savedItems = [];
  String? recommendationMessage;

  final Set<String> savedIds = {};

  final List<String> occasions = const [
    'Birthday',
    'Anniversary',
    'Graduation',
    'Wedding',
    'Festival',
    'Thank You',
    'Just Because',
  ];

  final List<String> relationships = const [
    'Friend',
    'Best Friend',
    'Mother',
    'Father',
    'Sibling',
    'Partner',
    'Colleague',
    'Child',
    'Other',
  ];

  List<String> get categories => ['All', ...giftData.keys];

  @override
  void initState() {
    super.initState();
    loadSavedGifts();
  }

  @override
  void dispose() {
    recipientController.dispose();
    interestsController.dispose();
    budgetController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<GiftItem> get visibleGifts {
    final query = searchController.text.trim().toLowerCase();

    return giftCatalogue.where((gift) {
      final categoryMatches =
          selectedCategory == 'All' || gift.category == selectedCategory;
      final searchMatches = query.isEmpty ||
          gift.name.toLowerCase().contains(query) ||
          gift.category.toLowerCase().contains(query) ||
          gift.description.toLowerCase().contains(query);
      return categoryMatches && searchMatches;
    }).toList();
  }

  Future<void> loadSavedGifts() async {
    setState(() => loadingSaved = true);

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/users/${widget.userId}/saved-gifts'),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = (data['saved_gifts'] as List? ?? []);

        final loaded = <GiftItem>[];
        final ids = <String>{};

        for (final item in raw) {
          if (item is! Map) continue;

          final row = Map<String, dynamic>.from(item);
          final giftData = row['gift_data'];
          final giftName = (row['gift_name'] ?? '').toString();

          GiftItem? gift;

          if (giftData is Map) {
            gift = GiftItem.fromJson(Map<String, dynamic>.from(giftData));
          }

          gift ??= giftCatalogue.cast<GiftItem?>().firstWhere(
                (g) => g?.name == giftName,
                orElse: () => null,
              );

          if (gift != null) {
            loaded.add(gift);
            ids.add(gift.id);
          }
        }

        if (!mounted) return;
        setState(() {
          savedItems = loaded;
          savedIds
            ..clear()
            ..addAll(ids);
        });
      }
    } catch (_) {
      // The rest of the catalogue remains available if saved-gift loading fails.
    } finally {
      if (mounted) setState(() => loadingSaved = false);
    }
  }

  Future<void> toggleSaved(GiftItem gift) async {
    final wasSaved = savedIds.contains(gift.id);

    setState(() {
      if (wasSaved) {
        savedIds.remove(gift.id);
        savedItems.removeWhere((g) => g.id == gift.id);
      } else {
        savedIds.add(gift.id);
        savedItems.insert(0, gift);
      }
    });

    try {
      final http.Response response;

      if (wasSaved) {
        response = await http.delete(
          Uri.parse(
            '$apiBaseUrl/users/${widget.userId}/saved-gifts/'
            '${Uri.encodeComponent(gift.name)}',
          ),
        ).timeout(const Duration(seconds: 12));
      } else {
        response = await http.post(
          Uri.parse('$apiBaseUrl/users/${widget.userId}/saved-gifts'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'gift_name': gift.name,
            'gift_data': gift.toJson(),
          }),
        ).timeout(const Duration(seconds: 12));
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Save request failed');
      }

      if (!mounted) return;
      showMessage(
        context,
        wasSaved ? 'Removed from saved gifts.' : 'Gift saved successfully!',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        if (wasSaved) {
          savedIds.add(gift.id);
          if (!savedItems.any((g) => g.id == gift.id)) {
            savedItems.add(gift);
          }
        } else {
          savedIds.remove(gift.id);
          savedItems.removeWhere((g) => g.id == gift.id);
        }
      });

      showMessage(
        context,
        'Could not update saved gifts. Check that the backend is running.',
      );
    }
  }

  Future<void> generateRecommendations() async {
  final recipient = recipientController.text.trim();
  final interests = interestsController.text
      .split(RegExp(r'[,;\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  final budget = int.tryParse(budgetController.text.trim()) ?? 0;

  if (recipient.length < 3 && interests.isEmpty) {
    showMessage(
      context,
      'Describe the recipient or enter their interests first.',
    );
    return;
  }

  setState(() {
    generating = true;
    recommendations = [];
    recommendationMessage = null;
  });

  try {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/recommend-gifts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipient_description':
            'Recipient: $recipient. Interests: ${interests.join(', ')}.',
        'recipient_name': recipient,
        'occasion': occasion,
        'relationship': relationship,
        'budget': budget > 0 ? budget.toString() : 'Not specified',
        'currency': currency,
        'interests': interests,
        'previous_gifts': savedItems.map((g) => g.name).toList(),
        'conversation_history': [],
        'refinement': '',
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('AI request failed');
    }

    final decoded = jsonDecode(response.body);
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : {};

    final rawGifts = decoded is List
        ? decoded
        : (data['gifts'] ??
            data['recommendations'] ??
            data['gift_ideas'] ??
            []);

    final aiGifts = <GiftItem>[];

    if (rawGifts is List) {
      for (final item in rawGifts) {
        if (item is! Map) continue;

        final gift = GiftItem.fromJson(
          Map<String, dynamic>.from(item),
        );

        // Budget must be respected, including AI price ranges.
        if (budget > 0 && gift.price > budget) continue;

        // Don't recommend the same gift again if it is already saved.
        if (savedIds.contains(gift.id)) continue;

        aiGifts.add(gift);
      }
    }

    if (!mounted) return;

    setState(() {
      recommendations = aiGifts.take(8).toList();
      recommendationMessage = aiGifts.isEmpty
          ? 'No suitable gifts found within your budget. Try increasing your budget or changing the interests.'
          : (data['message']?.toString() ??
              'AI recommendations for your recipient ✨');
    });
  } catch (_) {
    useLocalRecommendations(
      recipient: recipient,
      interests: interests.join(', '),
      budget: budget,
      message: 'Showing matching catalogue suggestions.',
    );
  } finally {
    if (mounted) setState(() => generating = false);
  }
}

  
void useLocalRecommendations({
  required String recipient,
  required String interests,
  required int budget,
  required String message,
}) {
  final keywords = '$recipient $interests'.toLowerCase();

  // Match the requested category using recipient interests.
  String? matchedCategory;

  if (RegExp(r'\b(accessor(y|ies)|jewell?ery|handbag|purse|wallet|watch|sunglasses)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Accessories';
  } else if (RegExp(r'\b(book|books|reading|read|novel|novels)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Books';
  } else if (RegExp(r'\b(toy|toys|kid|kids|child|children)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Toys';
  } else if (RegExp(r'\b(gym|fitness|workout|sport|sports)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Fitness';
  } else if (RegExp(r'\b(tech|computer|gaming|gadget|gadgets|earbuds)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Tech';
  } else if (RegExp(r'\b(beauty|makeup|skincare)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Beauty';
  } else if (RegExp(r'\b(fashion|clothes|clothing|style)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Fashion';
  } else if (RegExp(r'\b(home|decor|decoration|plant|plants)\b')
      .hasMatch(keywords)) {
    matchedCategory = 'Home Decor';
  }

  // Filter by category first. Never return the entire catalogue
  // when a specific category was requested but has no matches.
  var source = matchedCategory == null
      ? giftCatalogue
      : giftCatalogue
          .where((gift) => gift.category.toLowerCase() ==
              matchedCategory!.toLowerCase())
          .toList();

  // Enforce the budget.
  if (budget > 0) {
    source = source.where((gift) => gift.price <= budget).toList();
  }

  // Avoid recommending gifts that are already saved.
  source = source
      .where((gift) => !savedIds.contains(gift.id))
      .toList();

  final choices = source.take(8).toList();

  if (!mounted) return;

  setState(() {
    recommendations = choices;
    recommendationMessage = choices.isEmpty
        ? 'No matching gifts found within ₹$budget. Try different interests or increase your budget.'
        : message;
  });
}


  void openExplore() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreGiftsPage(
          savedIds: savedIds,
          onToggleSaved: toggleSaved,
        ),
      ),
    );
  }

  void openSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedGiftsPage(
          gifts: savedItems,
          savedIds: savedIds,
          loading: loadingSaved,
          onToggleSaved: toggleSaved,
          onRefresh: loadSavedGifts,
        ),
      ),
    );
  }

  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: primaryPink),
            SizedBox(width: 8),
            Text(
              'Giftly AI',
              style: TextStyle(
                color: deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
  tooltip: 'Explore Gifts',
  icon: const Icon(
    Icons.explore_outlined,
    color: Color(0xFF8B5CF6),
  ),
  onPressed: openExplore,
),
          IconButton(
            tooltip: 'Saved gifts',
            onPressed: openSaved,
            icon: const Icon(Icons.favorite_border, color: primaryPink),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'saved') openSaved();
              if (value == 'logout') logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false,
                child: Text(widget.userName),
              ),
              const PopupMenuItem(
                value: 'saved',
                child: Text('Saved gifts'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              'Welcome ${widget.userName} 💝',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Find thoughtful gifts for the people you love.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE1EF), Color(0xFFEAE1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find their perfect gift ✨',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell us about the person and we will find ideas for them.',
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: recipientController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient name',
                      hintText: 'e.g. Laasya',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: interestsController,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Interests and preferences',
                      hintText: 'e.g. reading, travel, cricket, art',
                      prefixIcon: Icon(Icons.favorite_outline),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: occasion,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Occasion'),
                          items: occasions
                              .map((o) =>
                                  DropdownMenuItem(value: o, child: Text(o)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => occasion = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: relationship,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Relationship'),
                          items: relationships
                              .map((r) =>
                                  DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => relationship = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Budget (optional)',
                            hintText: 'e.g. 1500',
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 55,
                        child: FilledButton(
                          onPressed:
                              generating ? null : generateRecommendations,
                          style: FilledButton.styleFrom(
                            backgroundColor: deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: generating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                ],
              ),
            ),
            const SizedBox(height: 27),

            if (recommendations.isNotEmpty) ...[
              const Text(
                'Gift ideas for you ✨',
                  style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (recommendationMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  recommendationMessage!,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ...recommendations.map(
                (gift) => GiftCard(
                  gift: gift,
                  isSaved: savedIds.contains(gift.id),
                  onSave: () => toggleSaved(gift),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ],
        ),
      ),
    );
  }
}

// SEPARATE EXPLORE SCREEN
// -----------------------------------------------------------------------------

class ExploreGiftsPage extends StatefulWidget {
  final String initialCategory;
  final Set<String> savedIds;
  final Future<void> Function(GiftItem) onToggleSaved;

  const ExploreGiftsPage({
    super.key,
    this.initialCategory = 'All',
    required this.savedIds,
    required this.onToggleSaved,
  });

  @override
  State<ExploreGiftsPage> createState() => _ExploreGiftsPageState();
}

class _ExploreGiftsPageState extends State<ExploreGiftsPage> {
  late String category;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<GiftItem> get results {
    final query = searchController.text.trim().toLowerCase();

    return giftCatalogue.where((gift) {
      final categoryMatch = category == 'All' || gift.category == category;
      final searchMatch = query.isEmpty ||
          gift.name.toLowerCase().contains(query) ||
          gift.description.toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = results;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Gifts',
          style: TextStyle(fontWeight: FontWeight.bold, color: deepPurple),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${items.length} gifts',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search books, toys, tech...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in ['All', ...giftData.keys])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c == 'All' ? 'All gifts' : c),
                      selected: category == c,
                      selectedColor: palePurple,
                      onSelected: (_) => setState(() => category = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No gifts found. Try another search.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 255,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final gift = items[index];
                      return GiftGridCard(
                        gift: gift,
                        isSaved: widget.savedIds.contains(gift.id),
                        onSave: () async {
                          await widget.onToggleSaved(gift);
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SAVED GIFTS SCREEN
// -----------------------------------------------------------------------------

class SavedGiftsPage extends StatefulWidget {
  final List<GiftItem> gifts;
  final Set<String> savedIds;
  final bool loading;
  final Future<void> Function(GiftItem) onToggleSaved;
  final Future<void> Function() onRefresh;

  const SavedGiftsPage({
    super.key,
    required this.gifts,
    required this.savedIds,
    required this.loading,
    required this.onToggleSaved,
    required this.onRefresh,
  });

  @override
  State<SavedGiftsPage> createState() => _SavedGiftsPageState();
}

class _SavedGiftsPageState extends State<SavedGiftsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Gifts ❤️',
          style: TextStyle(color: deepPurple, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await widget.onRefresh();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: widget.loading
          ? const Center(child: CircularProgressIndicator())
          : widget.gifts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 65)),
                        const SizedBox(height: 14),
                        const Text(
                          'No saved gifts yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the heart on a gift to save it here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${widget.gifts.length} gifts saved',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ...widget.gifts.map(
                      (gift) => GiftCard(
                        gift: gift,
                        isSaved: widget.savedIds.contains(gift.id),
                        onSave: () async {
                          await widget.onToggleSaved(gift);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// -----------------------------------------------------------------------------
// GIFT CARDS
// -----------------------------------------------------------------------------

class GiftCard extends StatelessWidget {
  final GiftItem gift;
  final bool isSaved;
  final VoidCallback onSave;

  const GiftCard({
    super.key,
    required this.gift,
    required this.isSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0E6EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: palePink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(gift.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gift.category,
                    style: const TextStyle(
                      color: deepPurple,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gift.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '₹${gift.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryPink,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gift.reason,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isSaved ? 'Remove saved gift' : 'Save gift',
              onPressed: onSave,
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? primaryPink : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GiftGridCard extends StatelessWidget {
  final GiftItem gift;
  final bool isSaved;
  final VoidCallback onSave;

  const GiftGridCard({
    super.key,
    required this.gift,
    required this.isSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFF0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [palePink, palePurple],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      gift.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: isSaved ? 'Remove saved gift' : 'Save gift',
                onPressed: onSave,
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? primaryPink : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            gift.category,
            style: const TextStyle(color: deepPurple, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            gift.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              gift.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          Text(
            '₹${gift.price}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryPink,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

String categoryEmoji(String category) {
  switch (category) {
    case 'Books':
      return '📚';
    case 'Toys':
      return '🧸';
    case 'Fitness':
      return '🏋️';
    case 'Fashion':
      return '👗';
    case 'Tech':
      return '🎧';
    case 'Beauty':
      return '💄';
    case 'Home Decor':
      return '🪴';
    case 'Accessories':
      return '👜';
    default:
      return '🎁';
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
