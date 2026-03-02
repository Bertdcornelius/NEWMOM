import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import '../../services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../widgets/ad_banner.dart';

class MomCareScreen extends StatefulWidget {
  const MomCareScreen({super.key});

  @override
  State<MomCareScreen> createState() => _MomCareScreenState();
}

class _MomCareScreenState extends State<MomCareScreen> {
  // List of Maps: { 'title': String, 'checked': bool }
  List<Map<String, dynamic>> _checklist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    final storage = context.read<LocalStorageService>();
    final saved = storage.getString('mom_care_checklist_v2');
    
    if (saved != null) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        _checklist = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        print("Error parsing mom care list: $e");
        _initDefaultList();
      }
    } else {
        _initDefaultList();
    }
    setState(() => _isLoading = false);
  }

  void _initDefaultList() {
      // Defaults for first launch
      _checklist = [
          {'title': 'Prenatal Vitamins', 'checked': false},
          {'title': 'Pain Medication', 'checked': false},
          {'title': 'Drink 2L Water', 'checked': false},
          {'title': 'Rest for 30 mins', 'checked': false},
      ];
      _saveState();
  }

  Future<void> _saveState() async {
    final storage = context.read<LocalStorageService>();
    await storage.saveString('mom_care_checklist_v2', jsonEncode(_checklist));
  }

  void _toggleItem(int index) {
    setState(() {
      _checklist[index]['checked'] = !(_checklist[index]['checked'] as bool);
    });
    _saveState();
  }

  void _addItem() {
      final controller = TextEditingController();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text("Add New Item"),
              content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: "Task Name", hintText: "e.g. Yoga"),
                  autofocus: true,
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                  TextButton(
                      onPressed: () {
                          if (controller.text.isNotEmpty) {
                              setState(() {
                                  _checklist.add({'title': controller.text, 'checked': false});
                              });
                              _saveState();
                              Navigator.pop(context);
                          }
                      }, 
                      child: Text("Add")
                  )
              ],
          ),
      );
  }

  void _editItem(int index) {
      final controller = TextEditingController(text: _checklist[index]['title']);
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text("Edit Item"),
              content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: "Task Name"),
                  autofocus: true,
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                  TextButton(
                      onPressed: () {
                          if (controller.text.isNotEmpty) {
                              setState(() {
                                  _checklist[index]['title'] = controller.text;
                              });
                              _saveState();
                              Navigator.pop(context);
                          }
                      }, 
                      child: Text("Save")
                  )
              ],
          ),
      );
  }

  void _deleteItem(int index) {
      // Confirm delete?
      setState(() {
          _checklist.removeAt(index);
      });
      _saveState();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted')));
  }

  void _showOptions(int index) {
      showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text('Edit', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3436))),
                          onTap: () {
                              Navigator.pop(context);
                              _editItem(index);
                          },
                      ),
                      ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3436))),
                          onTap: () {
                              Navigator.pop(context);
                              _deleteItem(index);
                          },
                      ),
                  ],
              ),
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      appBar: AppBar(title: Text('Mom Care')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
                ? Center(child: CircularProgressIndicator())
                : _checklist.isEmpty 
                    ? Center(child: Text("All cleared! Add something.", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3436))))
                    : ReorderableListView.builder(
                        itemCount: _checklist.length,
                        onReorder: (oldIndex, newIndex) {
                             setState(() {
                                 if (oldIndex < newIndex) {
                                   newIndex -= 1;
                                 }
                                 final item = _checklist.removeAt(oldIndex);
                                 _checklist.insert(newIndex, item);
                             });
                             _saveState();
                        },
                        itemBuilder: (context, index) {
                          final item = _checklist[index];
                          final isChecked = item['checked'] as bool;
                          
                          return Card(
                              key: ValueKey(item['title']), // Ideally use unique ID, but title ok for simple list
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: Checkbox(
                                    value: isChecked,
                                    side: BorderSide(color: isDark ? Colors.white.withOpacity(0.9) : Colors.black54, width: 2),
                                    onChanged: (v) => _toggleItem(index),
                                ),
                                title: Text(item['title'], style: TextStyle(
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked 
                                      ? (isDark ? Colors.white38 : Colors.grey) 
                                      : (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3436)),
                                )),
                                trailing: IconButton(
                                    icon: Icon(Icons.drag_handle, color: isDark ? Colors.white54 : Colors.grey),
                                    onPressed: null, // Reorderable list handles drag on long press usually, or trailing
                                ),
                                onTap: () => _toggleItem(index),
                                onLongPress: () => _showOptions(index),
                              ),
                          );
                        },
                      ),
          ),
          const AdBannerWidget(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            FloatingActionButton(
                heroTag: 'reset',
                mini: true,
                backgroundColor: Colors.orange[100],
                onPressed: () {
                    showDialog(
                        context: context, 
                        builder: (ctx) => AlertDialog(
                            title: Text("Reset All?"),
                            content: Text("Uncheck all items?"),
                            actions: [
                                TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text("Cancel")),
                                TextButton(onPressed: (){
                                    setState(() {
                                        for(var item in _checklist) { item['checked'] = false; }
                                    });
                                    _saveState();
                                    Navigator.pop(ctx);
                                }, child: Text("Reset")),
                            ]
                        )
                    );
                },
                child: Icon(Icons.refresh, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
                heroTag: 'add',
                onPressed: _addItem,
                child: Icon(Icons.add),
            ),
        ],
      ),
    );
  }
}
