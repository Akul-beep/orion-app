import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const apiKey = 'd2imrl9r01qhm15b6ufgd2imrl9r01qhm15b6ug0';
  const baseUrl = 'https://finnhub.io/api/v1';
  
  // Test profile endpoint
  print('Testing profile endpoint...');
  final profileResponse = await http.get(
    Uri.parse('$baseUrl/stock/profile2?symbol=AAPL&token=$apiKey'),
  );
  print('Profile Status: ${profileResponse.statusCode}');
  print('Profile Data: ${profileResponse.body}');
  
  // Test metrics endpoint
  print('\nTesting metrics endpoint...');
  final metricsResponse = await http.get(
    Uri.parse('$baseUrl/stock/metric?symbol=AAPL&metric=all&token=$apiKey'),
  );
  print('Metrics Status: ${metricsResponse.statusCode}');
  print('Metrics Data: ${metricsResponse.body}');
  
  // Test quote endpoint
  print('\nTesting quote endpoint...');
  final quoteResponse = await http.get(
    Uri.parse('$baseUrl/quote?symbol=AAPL&token=$apiKey'),
  );
  print('Quote Status: ${quoteResponse.statusCode}');
  print('Quote Data: ${quoteResponse.body}');
}
