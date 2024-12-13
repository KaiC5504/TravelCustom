import 'package:flutter/material.dart';

class CustomErrorMessage extends StatelessWidget {
  const CustomErrorMessage({
    super.key,
    required this.errorMessage,
  });

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 210, 127, 121),
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Adjust height dynamically
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Warning",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
                maxLines: 3, // Allow up to 3 lines
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> displayCustomErrorMessage(BuildContext context, String errorMessage) {
  return showDialog(
    context: context,
    barrierDismissible: true, // Allows closing by tapping outside
    builder: (context) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop(); // Dismiss on tap anywhere
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.only(top: 0), // Ensures it starts at the top
          child: Align(
            alignment: Alignment.topCenter, // Position the message at the top
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                child: GestureDetector(
                  onTap:
                      () {}, // Prevent dialog from closing when tapping on the message itself
                  child: CustomErrorMessage(errorMessage: errorMessage),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}




// void displayCustomErrorMessage(BuildContext context, String errorMessage) {
//   showModalBottomSheet(
//     context: context,
//     isDismissible: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return GestureDetector(
//         onTap: () {
//           Navigator.of(context).pop();
//         },
//         child: Container(
//           color: Colors.transparent,
//           child: GestureDetector(
//             onTap: () {},
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
//                 child: CustomErrorMessage(errorMessage: errorMessage),
//               ),
//             ),
//           ),
//         ), 
//       );
//     },
//   );
// }


// class CustomErrorMessage extends StatelessWidget {
//   const CustomErrorMessage({
//     super.key,
//     required this.errorMessage,
//   });

//   final String errorMessage;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         padding: const EdgeInsets.all(15),
//         height: 90,
//         decoration: const BoxDecoration(
//           color: Color.fromARGB(255, 210, 127, 121),
//           borderRadius: BorderRadius.all(
//             Radius.circular(20),
//           ),
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 50),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Warning",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     errorMessage,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ));
//   }
// }