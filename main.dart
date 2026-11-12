import 'package:material_ui/material_ui.dart';

// --- DATA & PURE CONVERSION FUNCTIONS ---
const lengthUnits = {'m': 1.0, 'km': 1000.0, 'mile': 1609.344, 'cm': 0.01};
const weightUnits = {'g': 1.0, 'kg': 1000.0, 'lb': 453.59237};
const tempUnits = ['C', 'F'];

double convert(double value, String from, String to, Map<String, double> units) {
  final base = value * units[from]!;
  return base / units[to]!;
}

double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;
double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

double convertTemperature(double value, String from, String to) {
  if (from == to) return value;
  if (from == 'C' && to == 'F') return celsiusToFahrenheit(value);
  if (from == 'F' && to == 'C') return fahrenheitToCelsius(value);
  return value;
}

// --- ENTRY POINT ---
void main() {
  assert((convert(1, 'km', 'm', lengthUnits) - 1000).abs() < 0.0001);
  assert((celsiusToFahrenheit(100) - 212).abs() < 0.0001);
  assert((fahrenheitToCelsius(32) - 0).abs() < 0.0001);

  runApp(const ConverterApp());
}

class ConverterApp extends StatelessWidget {
  const ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Converters',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F6F0), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB5C2B7),
          primary: const Color(0xFF88968A),
        ),
        cardTheme: CardThemeData( // Updated to fix the compiler error
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// --- HOME SCREEN ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Converters', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNavCard(
            context,
            title: 'Length',
            icon: Icons.straighten,
            units: lengthUnits.keys.toList(),
            factors: lengthUnits,
          ),
          const SizedBox(height: 12),
          _buildNavCard(
            context,
            title: 'Weight',
            icon: Icons.monitor_weight_outlined,
            units: weightUnits.keys.toList(),
            factors: weightUnits,
          ),
          const SizedBox(height: 12),
          _buildNavCard(
            context,
            title: 'Temperature',
            icon: Icons.thermostat,
            units: tempUnits,
            isTemperature: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> units,
    Map<String, double>? factors,
    bool isTemperature = false,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConverterPage(
                title: title,
                units: units,
                factors: factors,
                isTemperature: isTemperature,
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- SHARED CONVERTER SCREEN ---
class ConverterPage extends StatefulWidget {
  final String title;
  final List<String> units;
  final Map<String, double>? factors;
  final bool isTemperature;

  const ConverterPage({
    super.key,
    required this.title,
    required this.units,
    this.factors,
    this.isTemperature = false,
  });

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  late String _fromUnit;
  late String _toUnit;
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _fromUnit = widget.units.first;
    _toUnit = widget.units.length > 1 ? widget.units[1] : widget.units.first;
  }

  void _calculate() {
    setState(() {
      _errorText = '';
      _result = '';
      if (_controller.text.isEmpty) return;

      final value = double.tryParse(_controller.text);
      if (value == null) {
        _errorText = 'Please enter a valid number';
        return;
      }

      double rawResult;
      if (widget.isTemperature) {
        rawResult = convertTemperature(value, _fromUnit, _toUnit);
      } else {
        rawResult = convert(value, _fromUnit, _toUnit, widget.factors!);
      }
      
      _result = rawResult.toStringAsFixed(4).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Enter value',
                errorText: _errorText.isEmpty ? null : _errorText, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDropdown(
                  value: _fromUnit,
                  onChanged: (val) {
                    setState(() => _fromUnit = val!);
                    _calculate();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 32),
                  onPressed: _swapUnits,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildDropdown(
                  value: _toUnit,
                  onChanged: (val) {
                    setState(() => _toUnit = val!);
                    _calculate();
                  },
                ),
              ],
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), // Updated to fix the warning
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Result', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    _result.isEmpty ? '—' : '$_result $_toUnit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: widget.units.map((unit) {
          return DropdownMenuItem(value: unit, child: Text(unit));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
