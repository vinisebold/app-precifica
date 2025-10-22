import 'package:flutter/material.dart';

/// Chaves globais para os widgets que serão destacados no tutorial.
class TutorialKeys {
  // Passo 0: Abrir menu lateral
  static final GlobalKey menuButton = GlobalKey();
  
  // Passo 1: Criar primeira categoria
  static final GlobalKey addCategoryButton = GlobalKey();
  
  // Passo 2: Criar primeiro produto
  static final GlobalKey addProductFab = GlobalKey();
  
  // Passo 3: Destacar Gerir Perfis no menu
  static final GlobalKey manageProfilesDestination = GlobalKey();
  
  // Diálogos: salvar categoria e produto
  static final GlobalKey categoryDialogSaveButton = GlobalKey();
  static final GlobalKey productDialogSaveButton = GlobalKey();

  // Passo 3.1: Selecionar perfil de demonstração
  static final GlobalKey sampleProfileTile = GlobalKey();
  
  // Passo 3.2: Confirmar aplicação do perfil
  static final GlobalKey applyProfileButton = GlobalKey();
  
  // Passo final: Navegar pela navbar e conhecer o swipe
  static final GlobalKey categoryNavBar = GlobalKey();
}
