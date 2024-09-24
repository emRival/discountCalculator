import 'package:calculator_discount/database_helper.dart';
import 'package:calculator_discount/history_model.dart';
import 'package:calculator_discount/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(DiscountCalculatorApp());
}

class DiscountCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discount Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: DiscountCalculatorPage(),
    );
  }
}

class DiscountCalculatorPage extends StatefulWidget {
  @override
  _DiscountCalculatorPageState createState() => _DiscountCalculatorPageState();
}

class _DiscountCalculatorPageState extends State<DiscountCalculatorPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _originalPriceController =
      TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final List<TextEditingController> _discountControllers = [];
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  double? _finalPrice;
  double? _sellPrice;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _addDiscountField() {
    setState(() {
      _discountControllers.add(TextEditingController());
    });
  }

  void _calculateFinalPrice() {
    FocusScope.of(context).unfocus();
    if (_originalPriceController.text.isEmpty) return;

    String originalPriceText =
        _originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double originalPrice = double.tryParse(originalPriceText) ?? 0.0;
    double finalPrice = originalPrice;

    // Apply discounts
    for (var controller in _discountControllers) {
      if (controller.text.isNotEmpty) {
        String discountText = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
        double discount = double.tryParse(discountText) ?? 0.0;
        finalPrice -= finalPrice * (discount / 100);
      }
    }

    // Calculate sell price with profit
    String profitText =
        _profitController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double profit = double.tryParse(profitText) ?? 0.0;
    double sellPrice = finalPrice + profit;

    setState(() {
      _finalPrice = finalPrice;
      _sellPrice = sellPrice;
      _animationController.forward(from: 0.0);
    });

    _saveHistory();
  }

  void _saveHistory() async {
    String date = DateTime.now().toString();
    String originalPrice = _currencyFormatter.format(double.tryParse(
            _originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0.0);
    String discounts = _discountControllers
        .map((controller) => '${controller.text}%')
        .join(', ');
    String finalPrice = _currencyFormatter.format(_finalPrice);
    
 String profitText = _currencyFormatter.format(
        double.tryParse(_profitController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0);
    String sellPrice = _currencyFormatter.format(_sellPrice);
    DiscountHistory history = DiscountHistory(
      date: date,
      originalPrice: originalPrice,
      discount: discounts,
      finalPrice: finalPrice,
      profit: profitText,
      sellprice: sellPrice,
    );
    await DatabaseHelper.instance.insertHistory(history);
  }

  void _formatPriceInput() {
    String originalText =
        _originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (originalText.isNotEmpty) {
      _originalPriceController.value = TextEditingValue(
        text: _currencyFormatter.format(int.parse(originalText)),
        selection: TextSelection.collapsed(
            offset: _currencyFormatter.format(int.parse(originalText)).length),
      );
    }
  }

  void _formatProfitInput() {
    String profitText =
        _profitController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (profitText.isNotEmpty) {
      _profitController.value = TextEditingValue(
        text: _currencyFormatter.format(int.parse(profitText)),
        selection: TextSelection.collapsed(
            offset: _currencyFormatter.format(int.parse(profitText)).length),
      );
    }
  }

  @override
  void dispose() {
    _originalPriceController.dispose();
    _profitController.dispose();
    for (var controller in _discountControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discount Calculator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _originalPriceController.clear();
                _profitController.clear();
                _discountControllers.clear();
                _finalPrice = null;
                _sellPrice = null;
                _animationController.reset();
                // un-focus text field
                FocusScope.of(context).unfocus();
              });
            },
          ),
          // go to history page
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitle('Original Price'),
            _buildPriceField(_originalPriceController, 'Enter original price',
                _formatPriceInput),
            const SizedBox(height: 20),
            _buildTitle('Discounts'),
            ..._buildDiscountFields(),
            const SizedBox(height: 20),
            _buildAddDiscountButton(),
            const SizedBox(height: 20),
            _buildTitle('Desired Profit'),
            _buildPriceField(
                _profitController, 'Enter profit amount', _formatProfitInput),
            const SizedBox(height: 20),
            _buildCalculateButton(),
            if (_finalPrice != null && _sellPrice != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
    );
  }

  Widget _buildPriceField(
      TextEditingController controller, String hintText, Function formatInput) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => formatInput(),
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
          prefixIcon: const Icon(Icons.money, color: Colors.indigo),
          contentPadding: const EdgeInsets.all(15.0),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  List<Widget> _buildDiscountFields() {
    return List.generate(
      _discountControllers.length,
      (index) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountControllers[index],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter discount percentage',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  suffixIcon: const Icon(
                    Icons.percent,
                    color: Colors.indigo,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                setState(() {
                  _discountControllers.removeAt(index);
                });
              },
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        offset: Offset(2, 3),
                      )
                    ]),
                child: const Center(
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDiscountButton() {
    return ElevatedButton.icon(
      onPressed: _addDiscountField,
      icon: const Icon(
        Icons.add,
        color: Colors.white,
      ),
      label: const Text(
        'Add Discount',
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton.icon(
      onPressed: _calculateFinalPrice,
      icon: const Icon(
        Icons.calculate,
        color: Colors.white,
      ),
      label: const Text(
        'Calculate',
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );
  }

  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: InkWell(
        onTap: () {
          // copy to clipboard and show snackbar
          Clipboard.setData(ClipboardData(
              text:
                  'Final Price: ${_currencyFormatter.format(_finalPrice)}\nSell Price: ${_currencyFormatter.format(_sellPrice)}\nProfit: ${_currencyFormatter.format(_sellPrice! - _finalPrice!)}'));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Result copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(3, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Final Price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currencyFormatter.format(_finalPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sell Price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currencyFormatter.format(_sellPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
