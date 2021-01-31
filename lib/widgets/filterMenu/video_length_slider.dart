import 'package:flutter/material.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';

class VideoLengthSlider extends StatefulWidget {
  var onFilterUpdated;
  SearchFilter searchFilter;
  double initialStart;
  double initialEnd;

  static const double MAXIMUM_FILTER_LENGTH = 60;

  VideoLengthSlider(onFilterUpdated, SearchFilter lengthFilter) {
    this.onFilterUpdated = onFilterUpdated;
    this.searchFilter = lengthFilter;
    if (lengthFilter.filterValue == null || lengthFilter.filterValue.isEmpty) {
      initialStart = 0.0;
      initialEnd = MAXIMUM_FILTER_LENGTH;
    } else {
      List<String> split = searchFilter.filterValue.split("-");
      initialStart = double.parse(split.elementAt(0));
      initialEnd = double.parse(split.elementAt(1));
    }
  }

  @override
  _RangeSliderState createState() =>
      _RangeSliderState(RangeValues(initialStart, initialEnd));
}

class _RangeSliderState extends State<VideoLengthSlider> {
  RangeValues _values;

  _RangeSliderState(RangeValues rangeValues) {
    _values = rangeValues;
  }

  @override
  Widget build(BuildContext context) {
    return RangeSlider(
      values: _values,
      onChanged: (RangeValues values) {
        setState(() {
          _values = values;
        });
      },
      activeColor: Colors.black,
      inactiveColor: Colors.grey,
      labels: RangeLabels(
          _values.start.round().toString() + " min",
          _values.end < VideoLengthSlider.MAXIMUM_FILTER_LENGTH
              ? _values.end.round().toString() + " min"
              : "max"),
      max: VideoLengthSlider.MAXIMUM_FILTER_LENGTH,
      min: 0.0,
      divisions: 10,
      onChangeEnd: (values) {
        widget.searchFilter.filterValue = _values.start.round().toString() +
            "-" +
            _values.end.round().toString();
        widget.onFilterUpdated(widget.searchFilter);
      },
    );
  }
}
