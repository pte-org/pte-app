import 'package:flutter/material.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/app_typography.dart';

/// Anchored volume popup shared by task players.
class PteVolumeButton extends StatefulWidget {
  const PteVolumeButton({super.key, required this.volumeService});
  final VolumeService volumeService;

  @override
  State<PteVolumeButton> createState() => _PteVolumeButtonState();
}

class _PteVolumeButtonState extends State<PteVolumeButton> {
  final _buttonFocus = FocusNode();
  final _sliderFocus = FocusNode();
  final _menuController = MenuController();

  VolumeService get volumeService => widget.volumeService;

  @override
  void dispose() {
    _buttonFocus.dispose();
    _sliderFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    controller: _menuController,
    childFocusNode: _buttonFocus,
    onOpen: () => WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _menuController.isOpen) _sliderFocus.requestFocus();
    }),
    consumeOutsideTap: true,
    style: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.all(AppDimensions.spacingSm),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDefault),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    ),
    menuChildren: [
      SizedBox(
        width: AppDimensions.audioVolumePopupWidth,
        child: ValueListenableBuilder<double>(
          valueListenable: volumeService,
          builder: (context, volume, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.audioVolumeTooltip,
                        style: AppTypography.bodyBold,
                      ),
                    ),
                    SizedBox(
                      width: AppDimensions.audioVolumePercentWidth,
                      child: Text(
                        AppStrings.audioVolumePercent(volume),
                        textAlign: TextAlign.end,
                        style: AppTypography.audioPanelTime,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: AppDimensions.audioVolumeRowHeight,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: volume == 0
                          ? AppStrings.audioUnmuteTooltip
                          : AppStrings.audioMuteTooltip,
                      icon: Icon(
                        volume == 0 ? Icons.volume_off : Icons.volume_up,
                      ),
                      color: AppColors.audioPanelControl,
                      onPressed: volumeService.toggleMute,
                    ),
                    Expanded(
                      child: Slider(
                        focusNode: _sliderFocus,
                        value: volume,
                        activeColor: AppColors.primary,
                        semanticFormatterCallback:
                            AppStrings.audioVolumePercent,
                        onChanged: (value) => volumeService.value = value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
    builder: (context, controller, _) => ValueListenableBuilder<double>(
      valueListenable: volumeService,
      builder: (context, volume, _) => IconButton(
        focusNode: _buttonFocus,
        tooltip: AppStrings.audioVolumeTooltip,
        color: AppColors.audioPanelControl,
        icon: Icon(volume == 0 ? Icons.volume_off : Icons.volume_up),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    ),
  );
}
