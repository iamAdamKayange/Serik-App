import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool usePadding;
  final bool useSafeArea;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.usePadding = true,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive padding based on screen size
    double horizontalPadding;
    double verticalPadding;
    
    if (screenWidth < 360) {
      horizontalPadding = 12;
      verticalPadding = 8;
    } else if (screenWidth < 400) {
      horizontalPadding = 16;
      verticalPadding = 12;
    } else if (screenWidth < 480) {
      horizontalPadding = 20;
      verticalPadding = 16;
    } else {
      horizontalPadding = 24;
      verticalPadding = 20;
    }

    Widget content = child;

    if (usePadding) {
      content = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: content,
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int crossAxisCount;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid columns
    int columns;
    if (screenWidth < 360) {
      columns = 1;
    } else if (screenWidth < 480) {
      columns = 2;
    } else if (screenWidth < 768) {
      columns = 3;
    } else {
      columns = crossAxisCount;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // For very small screens, use a column instead of row
    if (screenWidth < 360 && children.length > 2) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: children.map((child) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: child,
        )).toList(),
      );
    }

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: children.map((child) => Padding(
        padding: EdgeInsets.only(right: spacing),
        child: child,
      )).toList(),
    );
  }
}
