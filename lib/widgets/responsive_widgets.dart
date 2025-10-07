import 'package:flutter/material.dart';

/// Widget responsivo que adapta seu conteúdo baseado no tamanho da tela
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wideScreen;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wideScreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width >= 1200) {
          return wideScreen ?? desktop ?? tablet ?? mobile;
        } else if (width >= 900) {
          return desktop ?? tablet ?? mobile;
        } else if (width >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Grid responsivo que se adapta ao número de colunas
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = mobileColumns;
        
        if (constraints.maxWidth >= 900) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= 600) {
          columns = tabletColumns;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            final childWidth = (constraints.maxWidth - 
                (spacing * (columns - 1))) / columns;
            return SizedBox(width: childWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}

/// Container responsivo que adapta padding baseado no tamanho da tela
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets padding;
        
        if (constraints.maxWidth >= 900) {
          padding = desktopPadding ?? const EdgeInsets.all(24.0);
        } else if (constraints.maxWidth >= 600) {
          padding = tabletPadding ?? const EdgeInsets.all(20.0);
        } else {
          padding = mobilePadding ?? const EdgeInsets.all(16.0);
        }

        return Padding(padding: padding, child: child);
      },
    );
  }
}

/// Card responsivo que adapta sua aparência
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return Card(
          elevation: elevation ?? (isWide ? 4.0 : 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(isWide ? 16.0 : 12.0),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(isWide ? 20.0 : 16.0),
            child: child,
          ),
        );
      },
    );
  }
}

/// Lista responsiva que muda de layout baseado no tamanho
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final bool isVertical;
  final double spacing;
  final ScrollController? controller;

  const ResponsiveList({
    super.key,
    required this.children,
    this.isVertical = true,
    this.spacing = 16.0,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        if (isVertical || !isWide) {
          return ListView.separated(
            controller: controller,
            itemCount: children.length,
            separatorBuilder: (context, index) => SizedBox(height: spacing),
            itemBuilder: (context, index) => children[index],
          );
        } else {
          return GridView.builder(
            controller: controller,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.2,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          );
        }
      },
    );
  }
}

/// AppBar responsivo que adapta suas ações
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final List<Widget>? mobileActions;
  final List<Widget>? desktopActions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.mobileActions,
    this.desktopActions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        List<Widget>? effectiveActions = actions;
        if (effectiveActions == null) {
          effectiveActions = isWide ? desktopActions : mobileActions;
        }

        return AppBar(
          title: Text(title),
          leading: leading,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          actions: effectiveActions,
          centerTitle: true,
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Formulário responsivo que adapta layout
class ResponsiveForm extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;
  final bool isTwoColumn;

  const ResponsiveForm({
    super.key,
    this.formKey,
    required this.children,
    this.isTwoColumn = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600 && isTwoColumn;
        
        if (isWide) {
          // Layout em duas colunas para telas maiores
          return Form(
            key: formKey,
            child: Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: children.map((child) {
                final childWidth = (constraints.maxWidth - 16.0) / 2;
                return SizedBox(width: childWidth, child: child);
              }).toList(),
            ),
          );
        } else {
          // Layout em coluna única para telas menores
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        }
      },
    );
  }
}

/// Botão responsivo que adapta tamanho
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final double? mobileHeight;
  final double? desktopHeight;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.mobileHeight = 48.0,
    this.desktopHeight = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final height = isWide ? desktopHeight : mobileHeight;
        
        return SizedBox(
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: child,
          ),
        );
      },
    );
  }
}

/// Utilitários para breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
  
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
}
