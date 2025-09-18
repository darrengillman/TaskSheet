//
//  SampleContent.swift
//  TaskSheet
//
//  Created by Darren Gillman on 18/09/2025.
//

struct SampleContent {
   private static let sampleContent = """
      System:
      \t- add entry for items on ignore list @next @done(2025-06-23)
      \t- importing Boxes multiple tiimes for a week creates multiple instances in the week @next @BUG @done(2025-07-23)
      \t- Finish importing weekly data @next @done(2025-06-25)
      \t\t- remove all other import buttons @done(2025-06-25)
      \t- Ensure that all BoxItems are deleted when a box is deleted as there are no date records in BoxItem to otherwise link it to the Week @done(2025-06-23)
      \t\tThere is a delete cascade rule from Box -> BoxItems which will take care of this (in theory)

      Packing Screen:
      \t- alter swaps listing so that it only highlights changes relevant to your station( i.e. station, all, notSet) @next @done(2025-07-29)
      \t- add split navigation @done(2025-07-23)
      \t- move toolbar into mian Nav bar @today @done(2025-09-03)
      \t- fix the layout bug where the supposedly static view scrolls up with the list view. @next @BUG
      """
   static let sampleDocument = TaskPaperDocument(content: sampleContent, fileName: "Sample File")
}
