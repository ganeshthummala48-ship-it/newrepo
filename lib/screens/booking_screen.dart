import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';
import '../utils/telangana_locations.dart';

class BookingScreen extends StatefulWidget {
  final String farmerName;

  const BookingScreen({
    Key? key,
    required this.farmerName,
  }) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ppbCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _acresCtrl = TextEditingController();
  final _mandalCtrl = TextEditingController(text: 'Amberpet');
  final _villageCtrl = TextEditingController(text: 'Amberpet Hub');

  String _selectedSeason = 'Kharif';
  String _selectedCrop = 'Paddy';
  String _selectedDistrict = 'Hyderabad';
  String _selectedMandal = 'Amberpet';
  String _selectedVillage = 'Amberpet Hub';
  String _selectedFilterDistrict = 'All';
  
  Map<String, int> _allocatedBags = {};
  
  // Dealer Selection
  List<dynamic> _dealers = [];
  bool _isLoadingDealers = false;
  int? _selectedDealerId;

  Map<String, dynamic>? get _selectedDealer {
    if (_selectedDealerId == null || _dealers.isEmpty) return null;
    return _dealers.firstWhere(
      (d) => d['id'] == _selectedDealerId,
      orElse: () => _dealers.first,
    );
  }

  String _selectedFertilizerType = 'Urea';
  int _bagsRequested = 1;

  // Bookings
  List<dynamic> _myBookings = [];
  bool _isLoadingBookings = false;

  List<String> get _districts => TelanganaLocations.districts;
  List<String> get _mandals => TelanganaLocations.getMandals(_selectedDistrict);
  List<String> get _villages => TelanganaLocations.getVillages(_selectedDistrict, _selectedMandal);

  final List<String> _crops = ['Paddy', 'Maize', 'Cotton', 'Chilli', 'Groundnut', 'Wheat', 'Sugarcane', 'Soybean', 'Sunflower'];
  final List<String> _fertilizerTypes = ['Urea', 'DAP', '20:20:0', 'MOP', 'NPK'];

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchMyBookings();
      }
    });
    _fetchDealers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ppbCtrl.dispose();
    _mobileCtrl.dispose();
    _aadharCtrl.dispose();
    _acresCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDealers() async {
    setState(() => _isLoadingDealers = true);
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/fertilizer/dealers?district=$_selectedDistrict'));
      if (response.statusCode == 200) {
        final dealersList = json.decode(response.body)['dealers'] as List? ?? [];
        setState(() {
          _dealers = dealersList;
          if (_dealers.isNotEmpty) {
            _selectedDealerId = _dealers.first['id'];
          } else {
            _selectedDealerId = null;
          }
        });
      }
    } catch (e) {
      print('Error fetching dealers: $e');
    }
    setState(() => _isLoadingDealers = false);
  }

  Future<void> _fetchAllocation() async {
    final acres = double.tryParse(_acresCtrl.text) ?? 0.0;
    if (acres <= 0) return;
    
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/fertilizer/allocation?crop=$_selectedCrop&acres=$acres'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawMap = (data['allocation'] ?? data['allocated_bags']) as Map<String, dynamic>? ?? {};
        setState(() {
          _allocatedBags = rawMap.map((key, value) => MapEntry(key, (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 1));
          _bagsRequested = 1;
        });
      }
    } catch (e) {
      print('Error fetching allocation: $e');
    }
  }

  Future<void> _fetchMyBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      String mobile = '';
      if (Hive.isBoxOpen('userBox')) {
        mobile = Hive.box('userBox').get('phone', defaultValue: '');
      } else if (Hive.isBoxOpen('profileBox')) {
        mobile = Hive.box('profileBox').get('phone', defaultValue: '');
      }
      
      final url = mobile.isNotEmpty 
          ? '${AppConstants.baseUrl}/fertilizer/bookings?mobile=$mobile'
          : '${AppConstants.baseUrl}/fertilizer/bookings';
          
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _myBookings = json.decode(response.body)['bookings'];
        });
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
    setState(() => _isLoadingBookings = false);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    } 

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...')));
    Position position = await Geolocator.getCurrentPosition();
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Match district
          String distName = place.administrativeArea ?? place.subAdministrativeArea ?? '';
          distName = distName.replaceAll(' District', '').trim();
          if (_districts.contains(distName)) {
            _selectedDistrict = distName;
          }
          
          String mandal = place.subLocality ?? place.locality ?? '';
          if (mandal.isNotEmpty) {
            _mandalCtrl.text = mandal;
            _selectedMandal = mandal;
          }
          
          String village = place.street ?? place.name ?? '';
          if (village.isNotEmpty) {
            _villageCtrl.text = village;
            _selectedVillage = village;
          }
        });
        _fetchDealers();
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
  }

  void _submitBooking() async {
    if (_selectedDealer == null) return;
    
    setState(() => _isSubmitting = true);
    try {
      final String name = widget.farmerName.trim().isNotEmpty ? widget.farmerName.trim() : 'Farmer';
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/fertilizer/booking'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ppb_number': _ppbCtrl.text.trim().isNotEmpty ? _ppbCtrl.text.trim() : 'PPB-001234',
          'farmer_name': name,
          'mobile': _mobileCtrl.text.trim().isNotEmpty ? _mobileCtrl.text.trim() : '9849012345',
          'aadhar_last4': _aadharCtrl.text.trim().isNotEmpty ? _aadharCtrl.text.trim() : '1234',
          'village': _selectedVillage.isNotEmpty ? _selectedVillage : 'Local Village',
          'mandal': _selectedMandal.isNotEmpty ? _selectedMandal : 'Local Mandal',
          'district': _selectedDistrict,
          'crop_type': _selectedCrop,
          'season': _selectedSeason,
          'land_acres': double.tryParse(_acresCtrl.text) ?? 1.0,
          'dealer_id': _selectedDealer!['id'],
          'fertilizer_type': _selectedFertilizerType,
          'bags_requested': _bagsRequested,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog(data['token'] ?? 'TS-FERT-SUCCESS', data['otp'] ?? '1234');
        _fetchDealers(); // refresh stock
      } else {
        if (!mounted) return;
        String errStr = 'Booking Failed';
        if (data is Map && data['detail'] != null) {
          final d = data['detail'];
          if (d is String) errStr = d;
          else if (d is List) errStr = d.map((x) => x['msg'] ?? x.toString()).join(', ');
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errStr)));
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Booking Catch Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
    setState(() => _isSubmitting = false);
  }

  void _showSuccessDialog(String token, String otp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Booking Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your iFMS fertilizer booking is successful.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Token Number:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text(token, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  SizedBox(height: 12),
                  Text('Simulated OTP (For Dealer):', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text(otp, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text('Please visit the dealer within 48 hours with your Aadhar and Pattadar Passbook.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentStep = 0;
                _tabController.animateTo(1);
              });
            },
            child: Text('View My Bookings'),
          ),
        ],
      ),
    );
  }

  // ==== STEPPER WIDGETS ====
  
  List<Step> _getSteps() {
    return [
      Step(
        title: Text('Identity'),
        content: _buildIdentityStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text('Land & Crop'),
        content: _buildLandCropStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text('Dealer & Quota'),
        content: _buildDealerStep(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text('Confirm'),
        content: _buildConfirmStep(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildIdentityStep() {
    return Column(
      children: [
        TextFormField(
          controller: _ppbCtrl,
          decoration: InputDecoration(
            labelText: 'Pattadar Passbook (PPB) Number',
            prefixIcon: Icon(Icons.book),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _mobileCtrl,
          decoration: InputDecoration(
            labelText: 'Aadhar-linked Mobile',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          maxLength: 10,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _aadharCtrl,
          decoration: InputDecoration(
            labelText: 'Aadhar Last 4 Digits',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
      ],
    );
  }

  Widget _buildLandCropStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _getCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: const Text("Use Current Location"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade50,
            foregroundColor: Colors.green.shade700,
            elevation: 0,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _districts.contains(_selectedDistrict) ? _selectedDistrict : _districts.first,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Telangana District',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city_rounded),
          ),
          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedDistrict = val;
                final newMandals = TelanganaLocations.getMandals(val);
                _selectedMandal = newMandals.first;
                _selectedVillage = TelanganaLocations.getVillages(val, _selectedMandal).first;
                _mandalCtrl.text = _selectedMandal;
                _villageCtrl.text = _selectedVillage;
              });
              _fetchDealers();
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _mandals.contains(_selectedMandal) ? _selectedMandal : _mandals.first,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mandal', border: OutlineInputBorder()),
                items: _mandals.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMandal = val;
                      _mandalCtrl.text = val;
                      final vList = TelanganaLocations.getVillages(_selectedDistrict, val);
                      _selectedVillage = vList.first;
                      _villageCtrl.text = _selectedVillage;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _villages.contains(_selectedVillage) ? _selectedVillage : _villages.first,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Village / Market', border: OutlineInputBorder()),
                items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedVillage = val;
                      _villageCtrl.text = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _acresCtrl,
          decoration: InputDecoration(
            labelText: 'Land Extent (Acres)',
            prefixIcon: Icon(Icons.landscape),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) => _fetchAllocation(),
        ),
        SizedBox(height: 16),
        Text('Season', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            ChoiceChip(
              label: Text('Kharif'),
              selected: _selectedSeason == 'Kharif',
              onSelected: (val) => setState(() => _selectedSeason = 'Kharif'),
            ),
            SizedBox(width: 8),
            ChoiceChip(
              label: Text('Rabi'),
              selected: _selectedSeason == 'Rabi',
              onSelected: (val) => setState(() => _selectedSeason = 'Rabi'),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text('Crop Type', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: _crops.map((c) => ChoiceChip(
            label: Text(c),
            selected: _selectedCrop == c,
            onSelected: (val) {
              setState(() => _selectedCrop = c);
              _fetchAllocation();
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDealerStep() {
    int maxAllowed = _allocatedBags[_selectedFertilizerType] ?? 0;
    
    // Find available stock for selected fertilizer
    int availableStock = 0;
    if (_selectedDealer != null && _selectedDealer!['stocks'] is List) {
      final st = (_selectedDealer!['stocks'] as List).firstWhere(
        (s) => s['type'] == _selectedFertilizerType,
        orElse: () => null,
      );
      if (st != null) {
        final rawVal = st['bags'] ?? st['available'] ?? 0;
        availableStock = (rawVal is num) ? rawVal.toInt() : (int.tryParse(rawVal.toString()) ?? 0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_allocatedBags.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eligible Quota (${_acresCtrl.text} Acres $_selectedCrop):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 12, runSpacing: 8,
                  children: _allocatedBags.entries.map((e) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                    child: Text('${e.key}: ${e.value} bags'),
                  )).toList(),
                )
              ],
            ),
          ),
          SizedBox(height: 16),
        ],

        Text('Select Fertilizer Type', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: _fertilizerTypes.map((f) => ChoiceChip(
            label: Text(f),
            selected: _selectedFertilizerType == f,
            onSelected: (val) {
              setState(() {
                _selectedFertilizerType = f;
                _bagsRequested = 1;
              });
            },
          )).toList(),
        ),
        SizedBox(height: 16),

        Text('Select Dealer in $_selectedDistrict', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _isLoadingDealers ? Center(child: CircularProgressIndicator()) 
        : _dealers.isEmpty ? Text('No dealers found in this district.')
        : DropdownButtonFormField<int>(
            value: (_selectedDealerId != null && _dealers.any((d) => d['id'] == _selectedDealerId))
                ? _selectedDealerId
                : (_dealers.isNotEmpty ? _dealers.first['id'] : null),
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _dealers.map((d) {
              final sList = (d['stocks'] as List? ?? []);
              final s = sList.firstWhere(
                (st) => st['type'] == _selectedFertilizerType,
                orElse: () => {'bags': 0, 'available': 0},
              );
              final rawStock = s['bags'] ?? s['available'] ?? 0;
              final stockCount = (rawStock is num) ? rawStock.toInt() : (int.tryParse(rawStock.toString()) ?? 0);
              return DropdownMenuItem<int>(
                value: d['id'] as int,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(d['name'], overflow: TextOverflow.ellipsis)),
                    Text('$stockCount bags', style: TextStyle(color: stockCount > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              _selectedDealerId = val;
              _bagsRequested = 1;
            }),
          ),

        if (_selectedDealer != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: Colors.green, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDealer!['name'] ?? 'Dealer Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Location: ${_selectedDealer!['village'] ?? ''}, ${_selectedDealer!['mandal'] ?? ''} Mandal (GPS: ${_selectedDealer!['lat'] ?? 0}, ${_selectedDealer!['lng'] ?? 0})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Text('Contact: ${_selectedDealer!['mobile'] ?? '9849012345'}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.verified_user_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text('Lic: ${_selectedDealer!['license'] ?? 'TS/FERT/2024'}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const Divider(height: 18),
                const Text('📦 Real-Time Dealer Fertilizer Stock:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ((_selectedDealer!['stocks'] as List? ?? [])).map<Widget>((st) {
                    final int count = (st['bags'] ?? st['available'] ?? 0) is num
                        ? (st['bags'] ?? st['available'] ?? 0).toInt()
                        : (int.tryParse((st['bags'] ?? st['available'] ?? 0).toString()) ?? 0);
                    final bool isCurrent = st['type'] == _selectedFertilizerType;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.green.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isCurrent ? Colors.green.shade600 : Colors.grey.shade300, width: isCurrent ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${st['type']}: ', style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                          Text(
                            '$count bags',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: count > 0 ? Colors.green.shade800 : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quantity (Bags):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: _bagsRequested > 1 ? () => setState(() => _bagsRequested--) : null,
                ),
                Text('$_bagsRequested', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: (_bagsRequested < maxAllowed && _bagsRequested < availableStock) 
                      ? () => setState(() => _bagsRequested++) : null,
                ),
              ],
            )
          ],
        ),
        if (maxAllowed == 0)
          Text('No allocation for this fertilizer.', style: TextStyle(color: Colors.red, fontSize: 12))
        else if (availableStock == 0)
          Text('Out of stock at this dealer.', style: TextStyle(color: Colors.red, fontSize: 12))
        else if (_bagsRequested >= maxAllowed)
          Text('Maximum eligible quota reached.', style: TextStyle(color: Colors.orange, fontSize: 12))
        else if (_bagsRequested >= availableStock)
          Text('Maximum available stock reached.', style: TextStyle(color: Colors.orange, fontSize: 12)),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('iFMS Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800))),
          Divider(),
          _buildSummaryRow('Farmer PPB:', _ppbCtrl.text),
          _buildSummaryRow('Mobile:', '${_mobileCtrl.text} (Aadhar: *${_aadharCtrl.text})'),
          _buildSummaryRow('Land Details:', '${_acresCtrl.text} Acres, $_selectedCrop ($_selectedSeason)'),
          Divider(),
          _buildSummaryRow('Dealer:', _selectedDealer?['name'] ?? ''),
          _buildSummaryRow('Fertilizer:', '$_bagsRequested Bags of $_selectedFertilizerType'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('An OTP will be generated. You must visit the dealer within 48 hours.', style: TextStyle(fontSize: 12))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // ==== MY BOOKINGS TAB ====
  
  Widget _buildMyBookings() {
    if (_isLoadingBookings) return const Center(child: CircularProgressIndicator());

    final filteredList = _myBookings.where((b) {
      if (_selectedFilterDistrict == 'All') return true;
      return (b['district'] ?? '').toString().toLowerCase().contains(_selectedFilterDistrict.toLowerCase());
    }).toList();

    return Column(
      children: [
        // District Filter Bar for My Bookings
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.filter_alt_rounded, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('District Filter:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilterDistrict,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                      items: ['All', ...TelanganaLocations.districts].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFilterDistrict = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No bookings found for $_selectedFilterDistrict district.', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMyBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final b = filteredList[index];
                      final bool isConfirmed = b['status'] == 'confirmed';
                      final Color statusColor = isConfirmed ? Colors.green : Colors.orange;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b['token'] ?? 'TS-FERT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Chip(
                                    label: Text((b['status'] ?? 'CONFIRMED').toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    backgroundColor: statusColor,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text('${b['bags_requested'] ?? 1} Bags of ${b['fertilizer_type'] ?? 'Urea'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.store, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(b['dealer_name'] ?? 'Depot', style: TextStyle(color: Colors.grey.shade700))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text('${b['village'] ?? ''}, ${b['mandal'] ?? ''}, ${b['district'] ?? 'Telangana'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('For: ${b['land_acres']} Acres ${b['crop_type']} (${b['season']})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              Text('PPB: ${b['ppb_number']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('OTP for Dealer: ${b['otp_code'] ?? '1234'}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                    Text('Pickup Valid 48h', style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return VoiceWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text('iFMS Fertilizer Booking'),
          backgroundColor: Colors.green.shade700,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: 'Book Fertilizer'),
              Tab(icon: Icon(Icons.history), text: 'My Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Stepper Flow
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Colors.green.shade700),
              ),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  // Validations
                  if (_currentStep == 0) {
                    if (_ppbCtrl.text.isEmpty || _mobileCtrl.text.length != 10 || _aadharCtrl.text.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all identity details correctly.')));
                      return;
                    }
                  } else if (_currentStep == 1) {
                    final acres = double.tryParse(_acresCtrl.text) ?? 0;
                    if (acres <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter valid land acres.')));
                      return;
                    }
                  } else if (_currentStep == 2) {
                    if (_selectedDealer == null || _bagsRequested <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select dealer and valid quantity.')));
                      return;
                    }
                  }
                  
                  if (_currentStep < _getSteps().length - 1) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitBooking();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  final isLastStep = _currentStep == _getSteps().length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isSubmitting 
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(isLastStep ? 'CONFIRM BOOKING' : 'NEXT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : details.onStepCancel,
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                              child: Text('BACK'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: _getSteps(),
              ),
            ),
            
            // Tab 2: My Bookings
            _buildMyBookings(),
          ],
        ),
      ),
    );
  }
}
