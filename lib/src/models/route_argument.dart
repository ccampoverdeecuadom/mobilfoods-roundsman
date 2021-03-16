import 'package:mvc_pattern/mvc_pattern.dart';

class RouteArgument {
  String id;
  String heroTag;
  dynamic param;
  String goTo;
  ControllerMVC controllerMVC;

  RouteArgument({this.id, this.heroTag, this.param, this.goTo, this.controllerMVC});

  @override
  String toString() {
    return '{id: $id, heroTag:${heroTag.toString()}}';
  }
}
