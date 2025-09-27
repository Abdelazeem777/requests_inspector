import 'package:flutter/material.dart';

class RunAgainButton extends StatefulWidget {
  const RunAgainButton({
    Key? key,
    required this.onTap,
    required this.isDarkMode, // Pass isDarkMode directly
  }) : super(key: key);

  final Future<void> Function() onTap;
  final bool isDarkMode; // New parameter

  @override
  _RunAgainButtonState createState() => _RunAgainButtonState();
}

class _RunAgainButtonState extends State<RunAgainButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // No need for a Selector here, as isDarkMode is passed as a direct prop
    return _isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        : InkWell(
            onTap: () {
              _setBusy();
              widget.onTap().whenComplete(_setReady);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Run',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ],
            ),
          );
  }

  void _setBusy() => setState(() => _isLoading = true);

  void _setReady() => setState(() => _isLoading = false);
}
