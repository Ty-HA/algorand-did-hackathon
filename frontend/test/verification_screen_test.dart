import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:algorand_hackathon/screens/verification_screen.dart';
import 'package:algorand_hackathon/services/api_service.dart';
import 'dart:ui';

@GenerateNiceMocks([MockSpec<ApiService>()])
import 'verification_screen_test.mocks.dart';

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  testWidgets('Complete verification flow with DID registration', (WidgetTester tester) async {
    // Configure la taille de l'écran pour le test
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    
    // Mock successful API response
    when(mockApiService.registerUser()).thenAnswer((_) async => {
      "address": "ALGO123456789",
      "passphrase": "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12"
    });

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VerificationScreen(apiService: mockApiService),
        ),
      ),
    ));

    // Verify initial state
    expect(find.text('Face Verification'), findsOneWidget);
    expect(find.text('Document Verification'), findsOneWidget);
    expect(find.text('Complete Verification'), findsOneWidget);
    
    // Start face verification
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Face Scan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // Verify face verification completed
    expect(find.text('Verified'), findsOneWidget);
    
    // Start document verification - scroll to make it visible
    await tester.dragUntilVisible(
      find.widgetWithText(ElevatedButton, 'Scan Document'),
      find.byType(SingleChildScrollView),
      const Offset(0, -100)
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Scan Document'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // Verify document verification completed
    expect(find.text('Verified'), findsNWidgets(2));
    
    // Complete verification - scroll to make it visible
    await tester.dragUntilVisible(
      find.widgetWithText(ElevatedButton, 'Complete Verification'),
      find.byType(SingleChildScrollView),
      const Offset(0, -100)
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Complete Verification'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // Verify API was called
    verify(mockApiService.registerUser()).called(1);
    
    // Verify success dialog
    expect(find.text('Verification Complete'), findsOneWidget);
    expect(find.text('Your identity has been successfully verified!'), findsOneWidget);
    
    // Verify DID information is shown
    expect(find.text('Your DID Address:'), findsOneWidget);
    expect(find.text('ALGO123456789'), findsOneWidget);
    
    // Clean up
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  });

  testWidgets('Verification fails when API call fails', (WidgetTester tester) async {
    // Configure la taille de l'écran
    await tester.binding.setSurfaceSize(const Size(1080, 1920));

    // Mock API failure
    when(mockApiService.registerUser())
        .thenThrow(Exception('Failed to register user'));

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VerificationScreen(apiService: mockApiService),
        ),
      ),
    ));

    // Complete verifications
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Face Scan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // Scroll to and tap Scan Document
    await tester.dragUntilVisible(
      find.widgetWithText(ElevatedButton, 'Scan Document'),
      find.byType(SingleChildScrollView),
      const Offset(0, -100)
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Scan Document'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // Scroll to and tap Complete Verification
    await tester.dragUntilVisible(
      find.widgetWithText(ElevatedButton, 'Complete Verification'),
      find.byType(SingleChildScrollView),
      const Offset(0, -100)
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Complete Verification'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify error dialog is shown
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Exception: Failed to register user'), findsOneWidget);

    // Clean up
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  });
}