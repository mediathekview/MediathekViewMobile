import 'package:flutter_ws/model/searchObject.dart';

class SearchQueryParser {

  getSearchObjectFromInput(String input){

    var channels = [];
    var topics = [];
    var titles = [];
    var descriptions = [];
    var generics = [];


//    Parse to Object here! -> then construc/t the query Object with this



    return new SearchObject(channels, topics, titles, descriptions, generics);
  }
}