import 'package:swan_frog/components/my_buttom.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // logo
            Icon(
              Icons.attach_money_rounded,
              size: 85,
              color: Theme.of(context).colorScheme.primary,
            ),

            Gap(5),
            //titile
            Text(
              "Swan & Frog",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.background),
            ),
            Gap(5),
            //subtitle
            Text(
              "一种人机交互的直播方式",
              style: TextStyle(
                color: Theme.of(context).colorScheme.background,
              ),
            ),
            Gap(20),

            //button
            MyButton(
                onTap: () {
                  Navigator.pushNamed(context, '/stream');
                },
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ))
          ],
        ),
      ),
    );
  }
}
