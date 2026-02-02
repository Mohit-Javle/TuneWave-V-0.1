// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

class GeniusService {
  // <<< IMPORTANT: Paste your Genius API Access Token here >>>
  static const String _accessToken =
      'ajF4qrsFis1E5LeRCr4yHcZU3b9GomHelNBMedsW_8UTFj1QaY0V7sq04dt7aIZB';

  static const String _apiUrl = 'https://api.genius.com';

  // Searches for a song on Genius and returns the song's path
  static Future<String?> _searchSongPath(String title, String artist) async {
    final query = Uri.encodeComponent('$title $artist');
    final url = Uri.parse('$_apiUrl/search?q=$query');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final hits = json['response']['hits'] as List;
        if (hits.isNotEmpty) {
          // Return the path of the first result
          return hits[0]['result']['path'];
        }
      }
    } catch (e) {
      print("Error searching song on Genius: $e");
    }
    return null;
  }

  // Scrapes the lyrics from a given Genius song path
  static Future<String?> _scrapeLyrics(String path) async {
    final url = Uri.parse('https://genius.com$path');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        dom.Document document = parser.parse(response.body);
        // The lyrics are in a div with a class that starts with "Lyrics__Container"
        // or a data attribute data-lyrics-container="true"
        final lyricsDiv = document.querySelector(
          'div[data-lyrics-container="true"]',
        );

        if (lyricsDiv != null) {
          return lyricsDiv.text.trim();
        }
      }
    } catch (e) {
      print("Error scraping lyrics: $e");
    }
    return null;
  }

  // Public method to get lyrics for a song
  static Future<String?> getLyrics(String title, String artist) async {
    final songPath = await _searchSongPath(title, artist);
    if (songPath != null) {
      return await _scrapeLyrics(songPath);
    }
    return null;
  }
}
