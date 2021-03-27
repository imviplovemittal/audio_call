import 'package:audio_call/models/room.dart';
import 'package:audio_call/models/user.dart';
import 'package:audio_call/pages/home/profile_page.dart';
import 'package:audio_call/pages/room/widgets/room_profile.dart';
import 'package:audio_call/util/data.dart';
import 'package:audio_call/util/history.dart';
import 'package:audio_call/util/style.dart';
import 'package:audio_call/widgets/round_button.dart';
import 'package:audio_call/widgets/round_image.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:audio_call/pages/welcome/welcome_page.dart';
import 'package:audio_call/util/style.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class RoomPage extends StatefulWidget {

  final Room room;

  const RoomPage({Key key, this.room}) : super(key: key);

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  static const APP_ID = '20996d85963e4feab983e63c409d7618';
  static const Token = '00620996d85963e4feab983e63c409d7618IABRa1x6is8KJWQa/7pzWFtrnC2UH7BFZYoTAUNZUUtZodJjSIgAAAAAEABfjXZEcCxgYAEAAQBwLGBg';
  int _counter = 0;
  bool _joined = false;
  int _remoteUid = null;
  bool _switch = false;
  RtcEngine engine;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Initialize the app
  Future<void> initPlatformState() async {
    await PermissionHandler().requestPermissions(
      [PermissionGroup.camera, PermissionGroup.microphone],
    );

    // Create RTC client instance
    engine = await RtcEngine.create(APP_ID);
    // Define event handling
    engine.setEventHandler(RtcEngineEventHandler(joinChannelSuccess: (String channel, int uid, int elapsed) {
      print('joinChannelSuccess $channel $uid');
      setState(() {
        _joined = true;
      });
    }, userJoined: (int uid, int elapsed) {
      print('userJoined $uid');
      showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New user joined"),
          content: Text("$uid joined"),
          actions: [FlatButton(onPressed: () {Navigator.pop(context);}, child: Text("OK"))],
        );
      });
      setState(() {
        _remoteUid = uid;
      });
    }, userOffline: (int uid, UserOfflineReason reason) {
      print('userOffline $uid');
      setState(() {
        _remoteUid = null;
      });
    }));
    // Enable video
    engine.enableAudio();
    engine.setEnableSpeakerphone(true);
    // await engine.enableVideo();
    // Join channel 123
    await engine.joinChannel(Token, '123', null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Text(
              'All rooms',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                History.pushPage(
                  context,
                  ProfilePage(
                    profile: myProfile,
                  ),
                );
              },
              child: RoundImage(
                path: myProfile.profileImage,
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            topLeft: Radius.circular(30),
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 80,
                top: 20,
              ),
              child: Column(
                children: [
                  buildTitle(widget.room.title),
                  SizedBox(
                    height: 30,
                  ),
                  buildSpeakers(widget.room.users.sublist(0, widget.room.speakerCount)),
                  buildOthers(widget.room.users.sublist(widget.room.speakerCount)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildBottom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          child: IconButton(
            onPressed: () {},
            iconSize: 30,
            icon: Icon(Icons.more_horiz),
          ),
        ),
      ],
    );
  }

  Widget buildSpeakers(List<User> users) {
    return GridView.builder(
      shrinkWrap: true,
      physics: ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 150,
      ),
      itemCount: users.length,
      itemBuilder: (gc, index) {
        return RoomProfile(
          user: users[index],
          isModerator: index == 0,
          isMute: index == 3,
          size: 80,
        );
      },
    );
  }

  Widget buildOthers(List<User> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Others in the room',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: ScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisExtent: 100,
          ),
          itemCount: users.length,
          itemBuilder: (gc, index) {
            return RoomProfile(
              user: users[index],
              size: 60,
            );
          },
        ),
      ],
    );
  }

  Widget buildBottom(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          RoundButton(
            onPressed: () {
              engine.leaveChannel();
              Navigator.pop(context);
            },
            color: Style.LightGrey,
            child: Text(
              '✌️ Leave quietly',
              style: TextStyle(
                color: Style.AccentRed,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Spacer(),
          RoundButton(
            onPressed: () {},
            color: Style.LightGrey,
            isCircle: true,
            child: Icon(
              Icons.add,
              size: 15,
              color: Colors.black,
            ),
          ),
          RoundButton(
            onPressed: () {},
            color: Style.LightGrey,
            isCircle: true,
            child: Icon(
              Icons.thumb_up,
              size: 15,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
