import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precifica/domain/entities/produto.dart';

import '../gestao_controller.dart';
import '../../shared/providers/modo_compacto_provider.dart';

import 'package:precifica/app/core/utils/currency_formatter.dart';
import 'package:precifica/app/core/utils/final_cursor_text_input_formatter.dart';

class ItemProduto extends ConsumerStatefulWidget {
  final Produto produto;
  final VoidCallback onDoubleTap;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final TextInputAction textInputAction;

  const ItemProduto({
    required this.produto,
    required this.onDoubleTap,
    required this.onTap,
    required this.focusNode,
    required this.onSubmitted,
    required this.textInputAction,
    super.key,
  });

  @override
  ConsumerState<ItemProduto> createState() => _ItemProdutoState();
}

class _ItemProdutoState extends ConsumerState<ItemProduto> {
  late final InputCursorFinalController _precoController;
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  bool _isDragging = false;
  bool _showPopAnimation = false;
  bool _showPressAnimation = false;

  @override
  void initState() {
    super.initState();
    final formatter = MoedaFormatter();
    _precoController = InputCursorFinalController(
      text: formatter
          .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
            text: (widget.produto.preco * 100).toInt().toString()),
      )
          .text,
    );
  }

  @override
  void dispose() {
    _precoController.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }

  void _startDrag() {
    if (mounted) {
      setState(() {
        _isDragging = true;
        _showPressAnimation = true;
      });
      HapticFeedback.lightImpact();
      ref.read(gestaoControllerProvider.notifier).setDraggingProduto(true);
      
      // Reseta a animação de pressão após completar
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _showPressAnimation = false);
        }
      });
    }
  }

  void _endDrag(DraggableDetails details) {
    if (!details.wasAccepted) {
      // Não usar animateBack com overlay customizado
      // Deixar Flutter gerenciar
      _finalizeDrag();
    } else {
      _finalizeDrag();
    }
  }

  void _cancelDrag(Velocity velocity, Offset offset) {
    // Não usar animateBack com overlay customizado
    // Deixar Flutter gerenciar
    _finalizeDrag();
  }

  void _finalizeDrag() {
    if (mounted) {
      // Ativa a animação de pop no item original
      setState(() {
        _isDragging = false;
        _showPopAnimation = true;
      });
      
      ref.read(gestaoControllerProvider.notifier).setDraggingProduto(false);
      
      // Reseta a animação de pop após completar
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _showPopAnimation = false);
        }
      });
    }
  }

  // MÉTODO DESABILITADO - estava causando problemas de overlay travado e scroll
  // O Flutter gerencia o feedback automaticamente sem precisar de overlay customizado
  /*
  void _animateBack(Offset dragEndOffset) {
    _finalizeDrag();
  }
  */

  Widget _buildDraggableFeedback() {
    final colorScheme = Theme.of(context).colorScheme;
    final modoCompacto = ref.read(modoCompactoProvider);
    
    final double verticalPadding = modoCompacto ? 4.0 : 8.0;
    final double horizontalPadding = modoCompacto ? 8.0 : 12.0;
    final double fontSize = modoCompacto ? 14.0 : 16.0;
    final double inputWidth = modoCompacto ? 100.0 : 120.0;

    return _FadeInFeedback(
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: MediaQuery.of(context).size.width - 16,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListTile(
            dense: modoCompacto,
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding * 0.5,
            ),
            title: Text(
              widget.produto.nome,
              style: TextStyle(fontSize: fontSize),
            ),
            trailing: SizedBox(
              width: inputWidth,
              // Espaço vazio para manter o layout, mas sem mostrar o preço
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final isAtivo = widget.produto.isAtivo;
    final modoCompacto = ref.watch(modoCompactoProvider);

    // Define os valores de padding e altura baseado no modo compacto
    final double verticalPadding = modoCompacto ? 4.0 : 8.0;
    final double horizontalPadding = modoCompacto ? 8.0 : 12.0;
    final double fontSize = modoCompacto ? 14.0 : 16.0;
    final double inputWidth = modoCompacto ? 100.0 : 120.0;

    // A construção do conteúdo do item (ListTile)
    final itemContent = ListTile(
      dense: modoCompacto,
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding * 0.5,
      ),
      title: Text(
        widget.produto.nome,
        style: TextStyle(
          decoration:
          isAtivo ? TextDecoration.none : TextDecoration.lineThrough,
          color: isAtivo ? null : colorScheme.outline,
          fontSize: fontSize,
        ),
      ),
      trailing: SizedBox(
        width: inputWidth,
        child: TextField(
          controller: _precoController,
          focusNode: widget.focusNode,
          textAlign: TextAlign.right,
          onSubmitted: (_) => widget.onSubmitted(),
          textInputAction: widget.textInputAction,
          onChanged: (novoPrecoFormatado) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              gestaoNotifier.atualizarPreco(
                  widget.produto.id, novoPrecoFormatado);
            });
          },
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            prefixStyle: TextStyle(fontSize: fontSize),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(modoCompacto ? 8.0 : 12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: modoCompacto ? 6.0 : 8.0,
              vertical: modoCompacto ? 6.0 : 8.0,
            ),
            isDense: modoCompacto,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            MoedaFormatter(),
          ],
        ),
      ),
    );

    // O GestureDetector para onTap (reativar) agora envolve tudo.
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isAtivo ? 1.0 : 0.4,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: _showPopAnimation 
              ? 1.03 
              : (_showPressAnimation ? 0.97 : 1.0),
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: _isDragging ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: !isAtivo,
              child: LongPressDraggable<Produto>(
                data: widget.produto,
                hapticFeedbackOnStart: false,
                onDragStarted: _startDrag,
                onDragEnd: _endDrag,
                onDraggableCanceled: _cancelDrag,
                feedback: _buildDraggableFeedback(),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: itemContent,
                ),
                child: GestureDetector(
                  onDoubleTap: widget.onDoubleTap,
                  child: itemContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeInFeedback extends StatefulWidget {
  final Widget child;

  const _FadeInFeedback({required this.child});

  @override
  State<_FadeInFeedback> createState() => _FadeInFeedbackState();
}

class _FadeInFeedbackState extends State<_FadeInFeedback> {
  double _opacity = 0.0;
  double _scale = 0.95;

  @override
  void initState() {
    super.initState();
    // Inicia o fade in e scale após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: _scale,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}