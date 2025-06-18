import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/request_inspector_sub_widgets/request_details_page.dart';
import 'package:requests_inspector/src/request_inspector_sub_widgets/request_item.dart';
import 'package:requests_inspector/src/request_inspector_sub_widgets/run_again_widget.dart';

import '../../requests_inspector.dart';

class Inspector extends StatefulWidget {
  const Inspector({
    super.key,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey;

  final GlobalKey<NavigatorState>? _navigatorKey;

  @override
  State<Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<Inspector> {
  bool showStopperDialogsAllowed() =>
      widget._navigatorKey?.currentContext != null;

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
            appBar: _buildAppBar(context),
            body: _buildBody(),
            floatingActionButton: _buildShareFloatingButton(),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    // Read the controller once for method calls that don't cause AppBar rebuilds.
    final inspectorCtrl = context.read<InspectorController>();

    return AppBar(
      // Use context.select for direct property access that triggers rebuilds
      backgroundColor: context.select((InspectorController c) => c.isDarkMode)
          ? Colors.black
          : Colors.white,
      title: const Text('Inspector 🕵️'),
      leading: IconButton(
        onPressed: inspectorCtrl.hideInspector,
        // Use context.select for direct property access that triggers rebuilds
        icon: Icon(Icons.close,
            color: context.select((InspectorController c) => c.isDarkMode)
                ? Colors.white
                : Colors.black87),
      ),
      actions: [
        // Consolidate selectors that depend on selectedTab and isDarkMode for the actions row.
        Selector<InspectorController, Tuple2<int, bool>>(
          selector: (_, controller) =>
              Tuple2(controller.selectedTab, controller.isDarkMode),
          builder: (context, data, _) {
            final selectedTab = data.item1;
            final isDarkMode = data.item2;

            return Row(
              children: [
                // JSON Tree Icon: Selector specifically for isTreeView and isDarkMode
                if (selectedTab == 1)
                  Selector<InspectorController, Tuple2<bool, bool>>(
                    selector: (_, controller) =>
                        Tuple2(controller.isTreeView, controller.isDarkMode),
                    builder: (context, iconData, __) {
                      final isTreeView = iconData.item1;
                      final iconIsDarkMode = iconData.item2;
                      return IconButton(
                        icon: isTreeView
                            ? Icon(Icons.text_fields,
                            color: iconIsDarkMode
                                ? Colors.white
                                : Colors.black87,
                            size: 20)
                            : Icon(Icons.account_tree_rounded,
                            color: iconIsDarkMode
                                ? Colors.white
                                : Colors.black87,
                            size: 20),
                        onPressed: inspectorCtrl
                            .toggleInspectorJsonView, // Use outer inspectorCtrl
                      );
                    },
                  ),
                // Dark Mode Icon: Selector specifically for isDarkMode
                Selector<InspectorController, bool>(
                  selector: (_, controller) => controller.isDarkMode,
                  builder: (context, iconIsDarkMode, __) {
                    return IconButton(
                      icon: iconIsDarkMode
                          ? const Icon(Icons.wb_sunny,
                          color: Colors.white, size: 20)
                          : const Icon(Icons.brightness_2,
                          color: Colors.black87, size: 20),
                      onPressed: inspectorCtrl
                          .toggleInspectorTheme, // Use outer inspectorCtrl
                    );
                  },
                ),
                // Separator: Its margin depends on selectedTab
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey[200],
                  margin: selectedTab == 0
                      ? null
                      : const EdgeInsets.only(right: 12),
                ),
                // Clear All / Run Again Button: Depends on selectedTab and isDarkMode
                selectedTab == 0
                    ? TextButton(
                  onPressed: () => _showAreYouSureDialog(
                    context,
                    onYes: inspectorCtrl
                        .clearAllRequests, // Use outer inspectorCtrl
                  ),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                        color:
                        isDarkMode ? Colors.white : Colors.black87),
                  ),
                )
                    : RunAgainButton(
                  key: ValueKey(inspectorCtrl.selectedRequest.hashCode),
                  // Key for efficient updates
                  onTap: inspectorCtrl.runAgain,
                  // Use outer inspectorCtrl
                  isDarkMode: isDarkMode, // Pass theme state directly
                ),
              ],
            );
          },
        ),
        _buildPopUpMenu(inspectorCtrl),
      ],
    );
  }

  Widget _buildPopUpMenu(InspectorController inspectorController) {
    return PopupMenuButton(
      icon: Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isDarkMode,
        builder: (context, isDarkMode, __) => Icon(Icons.more_vert,
            color: isDarkMode ? Colors.white : Colors.black87),
      ),
      itemBuilder: (context) => [
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            padding: EdgeInsets.zero,
            // Remove default padding for InkWell to fill
            child: InkWell(
              onTap: () => inspectorController.requestStopperEnabled =
              !inspectorController.requestStopperEnabled,
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
                        inspectorController.requestStopperEnabled = value,
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
              onTap: () => inspectorController.responseStopperEnabled =
              !inspectorController.responseStopperEnabled,
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
                        onChanged: (value) =>
                        inspectorController.responseStopperEnabled = value,
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

  Widget _buildBody() {
    return Selector<InspectorController, int>(
      selector: (_, inspectorController) => inspectorController.selectedTab,
      builder: (context, selectedTab, _) => Column(
        children: [
          _buildHeaderTabBar(context, selectedTab: selectedTab),
          _buildSelectedTab(context, selectedTab: selectedTab),
        ],
      ),
    );
  }

  Widget _buildHeaderTabBar(BuildContext context, {required int selectedTab}) {
    final inspectorController = context.read<InspectorController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabItem(
          context: context,
          title: 'All',
          isSelected: selectedTab == 0,
          isLeft: true,
          onTap: () => inspectorController.selectedTab = 0,
        ),
        _buildTabItem(
          context: context,
          title: 'Request Details',
          isSelected: selectedTab == 1,
          isLeft: false,
          onTap: () => inspectorController.selectedTab = 1,
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required bool isLeft,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.select((InspectorController c) => c.isDarkMode)
                ? (isSelected ? Theme.of(context).primaryColor : Colors.black87)
                : (isSelected ? Theme.of(context).primaryColor : Colors.white),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: context.select((InspectorController c) => c.isDarkMode)
                  ? Colors.white
                  : (isSelected ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab(BuildContext context, {required int selectedTab}) {
    return selectedTab == 0
        ? _buildAllRequests(context)
        : const RequestDetailsPage();
  }

  Widget _buildAllRequests(BuildContext context) {
    return Expanded(
      child: Selector<InspectorController, List<RequestDetails>>(
        selector: (_, controller) => controller.requestsList,
        shouldRebuild: (previous, next) => true,
        builder: (context, allRequests, _) => allRequests.isEmpty
            ? const Center(child: Text('No requests added yet'))
            : ListView.separated(
          padding:
          const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
          separatorBuilder: (_, __) => const SizedBox(height: 6.0),
          itemCount: allRequests.length,
          itemBuilder: (context, index) {
            final request = allRequests[index];
            return RequestItemWidget(
              request: request,
              // Modified onTap to pass context and request
              onTap: (itemContext, tappedRequest) {
                itemContext.read<InspectorController>().selectedRequest =
                    tappedRequest;
              },
            );
          },
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

            final controller = context.read<InspectorController>();
            final selectedRequest = controller.selectedRequest!;
            final isHttp = _isHttp(selectedRequest);

            final isCurl =
            isHttp ? await _showDialogShareType(context) : false;

            if (isCurl == null) return;

            controller.shareSelectedRequest(
              box == null
                  ? null
                  : box.localToGlobal(Offset.zero) & box.size,
              isCurl,
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

  Future<bool?> _showDialogShareType(BuildContext context) {
    return showDialog<bool?>(
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
            onPressed: () => Navigator.of(context).pop(true),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Normal Log',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}

