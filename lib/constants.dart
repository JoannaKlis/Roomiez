import 'package:flutter/material.dart';

// --- NOWA PALETA (Minimalist / Clean UI) ---

// Główny kolor akcentowy (Elegancki, głęboki morski)
// Używany do przycisków, aktywnych elementów i wyróżnień
const Color primaryColor = Color(0xFF0F766E);

// Tło całej aplikacji (Czysta biel)
// Dzięki temu aplikacja wygląda lekko i profesjonalnie
const Color backgroundColor = Color(0xFFFFFFFF);

// Główny tekst (Ciemny grafit / Prawie czarny)
// Lepszy dla oczu niż czysta czerń (#000000)
const Color textColor = Color(0xFF111827);

// Tekst pomocniczy (Szary)
// Używany do dat, podtytułów i placeholderów
const Color lightTextColor = Color(0xFF6B7280);

// --- NOWE ZMIENNE DLA NOWOCZESNEGO UI ---

// Kolor tła dla kart, pól tekstowych i "dymków"
// Bardzo jasny szary, żeby delikatnie odciąć się od białego tła
const Color surfaceColor = Color(0xFFF3F4F6);

// Kolor delikatnych ramek i linii podziału
const Color borderColor = Color(0xFFE5E7EB);

// Stary "accentColor" mapujemy na primary, żeby zachować spójność w starych plikach
const Color accentColor = primaryColor;

// Nowa, minimalistyczna czcionka
const String appFontFamily = 'Inter';