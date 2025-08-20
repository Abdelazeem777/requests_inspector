import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/shared_widgets/request_details_page.dart';
import 'package:requests_inspector/src/shared_widgets/request_item.dart';
import 'package:requests_inspector/src/shared_widgets/run_again_widget.dart';
import 'package:requests_inspector/src/shared_widgets/dart_model_generator_widget.dart';
import '../../requests_inspector.dart';
import '../enums/share_type_enum.dart';

class Inspector extends StatelessWidget {
  const Inspector({
    super.key,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey;

  final GlobalKey<NavigatorState>? _navigatorKey;

  bool showStopperDialogsAllowed() => _navigatorKey?.currentContext != null;

  @override
  Widget build(BuildContext context) {
    return Selector<InspectorController, bool>(
      selector: (_, controller) => controller.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          theme: isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.grey[800]!,
                  ),
                )
              : ThemeData.light(),
          home: Scaffold(
            appBar: _buildAppBar(isDarkMode),
            body: _buildBody(isDarkMode: isDarkMode),
            floatingActionButton: _buildShareFloatingButton(),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(bool isDarkMode) {
    return AppBar(
      // Set background color based on dark mode status
      backgroundColor: isDarkMode ? Colors.black : Colors.white,

      // Set default icon color for all icons inside AppBar (instead of per icon)
      iconTheme: IconThemeData(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),

      title: const Text('Inspector 🕵️'),

      leading: IconButton(
        // Use method from controller (doesn't require listening)
        onPressed: InspectorController().hideInspector,
        icon: const Icon(Icons.close), // Icon color handled by iconTheme
      ),

      // Build action buttons, separating logic for better readability
      actions: _buildActions(isDarkMode),
    );
  }

  List<Widget> _buildActions(
    bool isDarkMode,
  ) {
    return [
      Selector<InspectorController, int>(
        selector: (_, c) => c.selectedTab,
        builder: (context, selectedTab, _) {
          return Row(
            children: [
              selectedTab == 0
                  ? TextButton(
                      onPressed: () => _showAreYouSureDialog(
                        context,
                        onYes: InspectorController().clearAllRequests,
                      ),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    )
                  : RunAgainButton(
                      key: ValueKey(
                          InspectorController().selectedRequest.hashCode),
                      onTap: InspectorController().runAgain,
                      isDarkMode: isDarkMode,
                    ),
            ],
          );
        },
      ),
      _buildPopUpMenu(),
    ];
  }

  Widget _buildPopUpMenu() {
    return PopupMenuButton(
      icon: Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isDarkMode,
        builder: (context, isDarkMode, __) => Icon(Icons.more_vert,
            color: isDarkMode ? Colors.white : Colors.black87),
      ),
      itemBuilder: (context) => [
        // Dark Mode Toggle
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: InspectorController().toggleInspectorTheme,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode'),
                  Selector<InspectorController, bool>(
                    selector: (_, controller) => controller.isDarkMode,
                    builder: (context, isDarkMode, __) {
                      return Switch(
                        value: isDarkMode,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[700],
                        onChanged: (value) =>
                            InspectorController().toggleInspectorTheme(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // JSON Tree View Toggle
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: InspectorController().toggleInspectorJsonView,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('JSON Tree View'),
                  Selector<InspectorController, bool>(
                    selector: (_, controller) => controller.isTreeView,
                    builder: (context, isTreeView, __) {
                      return Switch(
                        value: isTreeView,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[700],
                        onChanged: (value) =>
                            InspectorController().toggleInspectorJsonView(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            padding: EdgeInsets.zero,
            // Remove default padding for InkWell to fill
            child: InkWell(
              onTap: () => InspectorController().requestStopperEnabled =
                  !InspectorController().requestStopperEnabled,
              child: Padding(
                // Add padding back for content
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Requests Stopper'),
                    Selector<InspectorController, bool>(
                      selector: (_, inspectorController) =>
                          inspectorController.requestStopperEnabled,
                      builder: (context, requestStopperEnabled, _) => Switch(
                        value: requestStopperEnabled,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[700],
                        onChanged: (value) =>
                            InspectorController().requestStopperEnabled = value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            padding: EdgeInsets.zero,
            // Remove default padding for InkWell to fill
            child: InkWell(
              onTap: () => InspectorController().responseStopperEnabled =
                  !InspectorController().responseStopperEnabled,
              child: Padding(
                // Add padding back for content
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Responses Stopper'),
                    Selector<InspectorController, bool>(
                      selector: (_, inspectorController) =>
                          inspectorController.responseStopperEnabled,
                      builder: (context, responseStopperEnabled, _) => Switch(
                        value: responseStopperEnabled,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[700],
                        onChanged: (value) => InspectorController()
                            .responseStopperEnabled = value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody({required bool isDarkMode}) {
    return Selector<InspectorController, int>(
      selector: (_, inspectorController) => inspectorController.selectedTab,
      builder: (context, selectedTab, _) => Column(
        children: [
          _buildTabBar(isDarkMode: isDarkMode, selectedTab: selectedTab),
          _buildSelectedTabBody(
              isDarkMode: isDarkMode, selectedTab: selectedTab),
        ],
      ),
    );
  }

  Widget _buildTabBar({required int selectedTab, required bool isDarkMode}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabItem(
          title: 'All',
          isDarkMode: isDarkMode,
          isSelected: selectedTab == 0,
          isLeft: true,
          isMiddle: false,
          onTap: () => InspectorController().selectedTab = 0,
        ),
        _buildTabItem(
          title: 'Request Details',
          isDarkMode: isDarkMode,
          isSelected: selectedTab == 1,
          isLeft: false,
          isMiddle: true,
          onTap: () => InspectorController().selectedTab = 1,
        ),
        _buildTabItem(
          title: 'Dart Model',
          isDarkMode: isDarkMode,
          isSelected: selectedTab == 2,
          isLeft: false,
          isMiddle: false,
          onTap: () => InspectorController().selectedTab = 2,
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required bool isDarkMode,
    required bool isLeft,
    required bool isMiddle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDarkMode
                ? (isSelected ? Colors.white : Colors.black87)
                : (isSelected ? Colors.black87 : Colors.white),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isDarkMode
                  ? (isSelected ? Colors.black87 : Colors.white)
                  : (isSelected ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabBody(
      {required int selectedTab, required bool isDarkMode}) {
    switch (selectedTab) {
      case 0:
        return _buildAllRequests(isDarkMode: isDarkMode);
      case 1:
        return const RequestDetailsPage();
      case 2:
        return const Expanded(child: DartModelGeneratorWidget());
      default:
        return _buildAllRequests(isDarkMode: isDarkMode);
    }
  }

  Widget _buildAllRequests({required bool isDarkMode}) {
    return Expanded(
      child: Selector<InspectorController, List<RequestDetails>>(
        selector: (_, controller) => controller.requestsList,
        shouldRebuild: (previous, next) => true,
        builder: (context, allRequests, _) => allRequests.isEmpty
            ? const Center(child: Text('No requests added yet'))
            : Selector<InspectorController, RequestDetails?>(
                selector: (_, controller) => controller.selectedRequest,
                builder: (context, selectedRequest, _) => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 6.0),
                  separatorBuilder: (_, __) => const SizedBox(height: 6.0),
                  itemCount: allRequests.length,
                  itemBuilder: (context, index) {
                    final request = allRequests[index];
                    return RequestItemWidget(
                      request: request,
                      isSelected: selectedRequest == request,
                      isDarkMode: isDarkMode,
                      onTap: (itemContext, tappedRequest) {
                        InspectorController().selectedRequest = tappedRequest;
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _showAreYouSureDialog(
    BuildContext context, {
    required VoidCallback onYes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure? 🤔'),
        content:
            const Text('This will clear all requests added to the inspector'),
        actions: [
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onYes();
            },
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('No', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareFloatingButton() {
    return Selector<InspectorController, bool>(
      selector: (_, inspectorController) =>
          inspectorController.selectedTab == 1 &&
          inspectorController.selectedRequest != null,
      builder: (context, showShareButton, _) => showShareButton
          ? FloatingActionButton(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: const Icon(Icons.share),
              onPressed: () async {
                final box = context.findRenderObject() as RenderBox?;

                final selectedRequest = InspectorController().selectedRequest!;
                final isHttp = _isHttp(selectedRequest);

                final shareType =
                    isHttp ? await _showDialogShareType(context) : null;

                if (shareType == null) return;

                InspectorController().shareSelectedRequest(
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                  shareType: shareType,
                );
              })
          : const SizedBox(),
    );
  }

  bool _isHttp(RequestDetails selectedRequest) {
    return selectedRequest.requestMethod == RequestMethod.GET ||
        selectedRequest.requestMethod == RequestMethod.POST ||
        selectedRequest.requestMethod == RequestMethod.PUT ||
        selectedRequest.requestMethod == RequestMethod.PATCH ||
        selectedRequest.requestMethod == RequestMethod.DELETE;
  }

  Future<ShareType?> _showDialogShareType(BuildContext context) {
    return showDialog<ShareType?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Normal Log or cURL command? 🤔'),
        content: const Text(
            'The cURL command is more useful for exporting to Postman or run it again from terminal'),
        actions: [
          TextButton(
            child: const Text(
              'cURL Command',
              style: TextStyle(color: Colors.green),
            ),
            onPressed: () => Navigator.of(context).pop(ShareType.CurlCommand),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ShareType.NormalLog),
            child: const Text(
              'Normal Log',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ShareType.Both),
            child: const Text(
              'Both',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
