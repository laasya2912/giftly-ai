
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
void main() {
  runApp(const GiftApp());
}

class GiftApp extends StatelessWidget {
  const GiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Giftly AI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF9F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B5DE5),
        ),
        fontFamily: 'Arial',
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isRegister = false;
  bool isLoading = false;
  bool hidePassword = true;

  static const String baseUrl = 'http://127.0.0.1:8000';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final endpoint = isRegister ? '/register' : '/login';

      final Map<String, dynamic> requestData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      if (isRegister) {
        requestData['name'] = _nameController.text.trim();
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (isRegister) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
            ),
          );

          setState(() {
            isRegister = false;
            _passwordController.clear();
          });
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GiftHomePage(userName: responseData['user']['name']),
            ),
          );
        }
      } else {
        final error = responseData['detail'] ?? 'Something went wrong';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to server. Please start the backend.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C3CE9);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        size: 64,
                        color: purple,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Giftly AI',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? 'Create your account'
                            : 'Welcome back!',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (isRegister) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (isRegister && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isRegister ? 'Create Account' : 'Login',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  isRegister = !isRegister;
                                  _formKey.currentState?.reset();
                                  _passwordController.clear();
                                });
                              },
                        child: Text(
                          isRegister
                              ? 'Already have an account? Login'
                              : "Don't have an account? Register",
                          style: const TextStyle(color: purple),
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

class GiftHomePage extends StatefulWidget {
  final String userName;

  const GiftHomePage({
    super.key,
    required this.userName,
  });

  @override
  State<GiftHomePage> createState() => _GiftHomePageState();
}
class _GiftHomePageState extends State<GiftHomePage> {
  final nameController = TextEditingController();
  final occasionController = TextEditingController();

  String relationship = 'Friend';
  String budget = '₹500 – ₹1,000';
  String interest = 'Technology';
  bool showResults = false;

  final List<Map<String, String>> allGifts = [
    {'emoji': '🎧', 'name': 'Wireless Earbuds', 'price': '₹799', 'amount': '799', 'category': 'Technology', 'reason': 'A useful everyday gift for someone who loves technology and music.', 'tag': 'POPULAR'},
    {'emoji': '⌚', 'name': 'Smart Watch', 'price': '₹1,999', 'amount': '1999', 'category': 'Technology', 'reason': 'A practical tech gift for daily activities and fitness.', 'tag': 'TECH PICK'},
    {'emoji': '🔋', 'name': 'Portable Power Bank', 'price': '₹499', 'amount': '499', 'category': 'Technology', 'reason': 'A handy gift to keep their devices charged on the go.', 'tag': 'USEFUL'},
    {'emoji': '👛', 'name': 'Stylish Wallet', 'price': '₹699', 'amount': '699', 'category': 'Fashion', 'reason': 'A stylish accessory they can use every day.', 'tag': 'STYLE PICK'},
    {'emoji': '👜', 'name': 'Everyday Tote Bag', 'price': '₹399', 'amount': '399', 'category': 'Fashion', 'reason': 'A cute and practical accessory for outings or college.', 'tag': 'BUDGET PICK'},
    {'emoji': '📔', 'name': 'Personalised Journal', 'price': '₹599', 'amount': '599', 'category': 'Books', 'reason': 'A thoughtful gift for writing down ideas and memories.', 'tag': 'THOUGHTFUL'},
    {'emoji': '📚', 'name': 'Book + Bookmark Set', 'price': '₹499', 'amount': '499', 'category': 'Books', 'reason': 'A lovely choice for someone who enjoys reading.', 'tag': 'READER PICK'},
    {'emoji': '🎨', 'name': 'Creative Art Kit', 'price': '₹899', 'amount': '899', 'category': 'Art', 'reason': 'Encourages their creativity and love of making art.', 'tag': 'CREATIVE'},
    {'emoji': '🎮', 'name': 'Gaming Accessories', 'price': '₹999', 'amount': '999', 'category': 'Gaming', 'reason': 'A fun upgrade for someone who loves gaming.', 'tag': 'GAMER PICK'},
    {'emoji': '✈️', 'name': 'Travel Organiser Kit', 'price': '₹799', 'amount': '799', 'category': 'Travel', 'reason': 'Keeps travel essentials organised on every trip.', 'tag': 'TRAVEL PICK'},
    {'emoji': '🍫', 'name': 'Chocolate Gift Box', 'price': '₹499', 'amount': '499', 'category': 'Food', 'reason': 'A sweet little surprise for a special occasion.', 'tag': 'SWEET PICK'},
    {'emoji': '☕', 'name': 'Custom Coffee Mug', 'price': '₹299', 'amount': '299', 'category': 'Food', 'reason': 'A personalised everyday reminder of your thoughtfulness.', 'tag': 'BUDGET PICK'},
    {'emoji': '🏋️', 'name': 'Fitness Essentials Kit', 'price': '₹899', 'amount': '899', 'category': 'Fitness', 'reason': 'A motivating gift for someone who enjoys staying active.', 'tag': 'ACTIVE PICK'},
    {'emoji': '🎁', 'name': 'Surprise Gift Box', 'price': '₹899', 'amount': '899', 'category': 'All', 'reason': 'A cheerful mix of small surprises for someone special.', 'tag': 'GIFT BOX'},
    {'emoji': '🖼️', 'name': 'Personalised Photo Frame', 'price': '₹399', 'amount': '399', 'category': 'All', 'reason': 'A keepsake to celebrate your memories together.', 'tag': 'MEMORY MAKER'},
  ];

  List<Map<String, String>> recommendedGifts = [];

  int _maxBudget() {
    if (budget == 'Under ₹500') return 499;
    if (budget == '₹500 – ₹1,000') return 1000;
    if (budget == '₹1,000 – ₹2,500') return 2500;
    return 100000;
  }

  void findGifts() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the recipient name.')),
      );
      return;
    }

    final maxBudget = _maxBudget();
    final affordable = allGifts.where(
      (gift) => int.parse(gift['amount']!) <= maxBudget,
    ).toList();

    final matched = affordable.where(
      (gift) => gift['category'] == interest || gift['category'] == 'All',
    ).toList();

    setState(() {
      recommendedGifts = matched.isNotEmpty ? matched : affordable;
      showResults = true;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    occasionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F6),
        title: const Row(
          children: [
            Text('🎁 ', style: TextStyle(fontSize: 25)),
            Text(
              'Giftly AI',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7041A6),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E5FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI GIFT FINDER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7041A6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7041A6), Color(0xFFB58AE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ YOUR PERSONAL GIFT ASSISTANT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                   const SizedBox(height: 22),
Text(
  'Welcome, ${widget.userName}!',
  style: const TextStyle(
    color: Colors.white,
    fontSize: 35,
    height: 1.15,
    fontWeight: FontWeight.bold,
  ),
),
                    const SizedBox(height: 12),
                    const Text(
                      'Tell us who you are shopping for. We will help '
                      'you discover thoughtful gift ideas.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Personalised ideas • Budget-friendly picks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Let’s find the perfect gift',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292333),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'A few details help us find a thoughtful match.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 22),
              _sectionLabel('WHO IS IT FOR?'),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  'Recipient name',
                  Icons.person_outline,
                ),
              ),
              const SizedBox(height: 15),
              _sectionLabel('YOUR RELATIONSHIP'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: relationship,
                decoration: _inputDecoration(
                  'Relationship',
                  Icons.favorite_border,
                ),
                items: [
                  'Friend',
                  'Best Friend',
                  'Mother',
                  'Father',
                  'Sibling',
                  'Partner',
                  'Colleague',
                  'Other',
                ].map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => relationship = value);
                  }
                },
              ),
              const SizedBox(height: 15),
              _sectionLabel('WHAT IS THE OCCASION?'),
              const SizedBox(height: 8),
              TextField(
                controller: occasionController,
                decoration: _inputDecoration(
                  'e.g. Birthday, Anniversary, Just because',
                  Icons.celebration_outlined,
                ),
              ),
              const SizedBox(height: 15),
              _sectionLabel('YOUR BUDGET'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Under ₹500',
                  '₹500 – ₹1,000',
                  '₹1,000 – ₹2,500',
                  '₹2,500+',
                ].map((item) {
                  final selected = budget == item;
                  return ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => setState(() => budget = item),
                    selectedColor: const Color(0xFFE8D7FF),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF9B5DE5)
                          : Colors.black12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _sectionLabel('WHAT DO THEY LOVE?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Technology',
                  'Fashion',
                  'Books',
                  'Art',
                  'Gaming',
                  'Travel',
                  'Food',
                  'Fitness',
                ].map((item) {
                  final selected = interest == item;
                  return ChoiceChip(
                    avatar: Text(_interestEmoji(item)),
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => setState(() => interest = item),
                    selectedColor: const Color(0xFFE8D7FF),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: findGifts,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Find My Perfect Gifts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8050B5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (showResults) ...[
                const SizedBox(height: 32),
                Text(
                  'Gift ideas for ${nameController.text.trim()} 💝',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${occasionController.text.trim().isEmpty ? 'A special occasion' : occasionController.text.trim()}'
                  ' • $relationship • $budget',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Here are some ideas to get you started:',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ...recommendedGifts.map((gift) => _giftCard(gift)),
                const SizedBox(height: 10),
                const Text(
                  'Suggestions are matched to the selected interest and budget. '
                  'Prices are estimates and may vary.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Made with 💜 to make gifting special',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.bold,
        color: Color(0xFF755A91),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF8D69B3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9E1EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9E1EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF9B5DE5),
          width: 1.5,
        ),
      ),
    );
  }

  String _interestEmoji(String item) {
    const emojis = {
      'Technology': '🎧',
      'Fashion': '👗',
      'Books': '📚',
      'Art': '🎨',
      'Gaming': '🎮',
      'Travel': '✈️',
      'Food': '🍫',
      'Fitness': '🏋️',
    };
    return emojis[item] ?? '🎁';
  }

  Widget _giftCard(Map<String, String> gift) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEDE5F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                gift['emoji']!,
                style: const TextStyle(fontSize: 29),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift['tag']!,
                    style: const TextStyle(
                      color: Color(0xFF8050B5),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gift['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gift['reason']!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              gift['price']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF7041A6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
