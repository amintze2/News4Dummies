# Product Requirements: News App

Template \+ Claude Skills: [https://github.com/madooei/chat-template/tree/phase-4](https://github.com/madooei/chat-template/tree/phase-4)  
Name ideas:

* Context / Contextual  
* Unpacked  
* Sidebar  
* Loop

## Overview

#### Problem Statement

Keeping up to date with the news is difficult. I often don’t have time to search for the news I actually want to see, and more often than not I don’t even *know* what I want to see. Moreover, reading the news isn’t fun. I frequently find myself putting an article down halfway through because there was a word, phrase, or concept that I didn’t understand, and the friction of putting the article down and going to look it up is too laborious. Separately, I also find myself craving the feeling of getting a notification from a social media app or wanting to scroll on a feed, even though I don’t use social media.

#### Proposed Solution

A centralized mobile app that utilizes the same engagement optimization strategies that social media uses and enhances the reading process to make consuming the news fun and easy. The app will aim to solve a few issues that “Gen Z” seems to face simultaneously: the crave for instant-gratification, a lack of awareness of current events, difficulties retaining the information once it is learned, and a high barrier to entry to start digesting news.

#### Target Users

Anna and Lucy, we will be the only users (and our friends, if we make any other ones).

## Requirements

#### Functional Requirements

Essential (Must-Have)

* Users will be able to “log in” with just their name (Anna and Lucy are the only intended users) upon opening the application. Articles will only be loaded for the logged in user.  
* The mobile application will have different tabs, corresponding to the main functionalities of the software:  
  * **What’s New**: displays the headline and summary of news stories from an RSS feed  
  * **My Articles**: allows you to read each of the “loaded” articles *within* the app interactively  
    * Collection View: shows all of the articles that you have saved, when you click on one, the article is opened in Reading Mode  
    * Reading Mode: allows you to read the article and toggle on/off Interactive Mode  
  * **Learn**: uses Free Spaced Repetition Scheduler (FSRS) to help users master concepts they have encountered, and also provides access to pre-made decks  
* Aggregating headlines from different sources in a “**What’s New**” feed  
  * Open-access outlets to full article content include: AP, Reuters, NPR, and BBC  
* In the feed, you can click on a headline (links provided by RSS feeds) to take you to the article in Safari  
* When you click on a shortcut in iPhone, it will send the text from the article in json to our app, then users can navigate back to the app and can view the full article   
* When you activate the shortcut (the article text is sent to the app), the article it moves from the “**What’s New**” feed to the “**My Articles**” section  
* In the “**My Articles**” section there is the same visual component of the display of each article in the “**What’s New**” feed with headlines (and the avatar of the source if done), but there will only be articles that we have the full text for. This will be in order of most recently added   
* You can add custom tags to different articles in the “**My Articles**” section and you can view in the “**My Articles**” section where you can filter the articles by just those tags, viewing a certain media source, or just viewing a particular journalist's articles.    
* When you are reading a full article in the reading view of the “**My Articles**” tab, you can click a button in the top panel to go into Interactive Mode, where you can drag your finger over a section of text and it highlights that section. The Interactive Mode button should toggle to a “x” when tapped will exit Interactive Mode. You can’t scroll through the article in Interactive Mode, it just freezes the text in the moment.  
* There are two interaction options: **AI explain** and **AI chat**. ai explain will use a system prompt and return a definition of a term to the user. **AI chat** will open up a chatbot window to allow the user to converse about the highlighted phrase in question. These highlighted phrases can also be **Added to study set**  
* When in the Reader View, the **Define** feature can also be activated by double tapping a word.  
* Any word that is **Defined** will be saved and can be viewed later in the “**Word Bank”** part in the “**Learn”** section.  
* In Interactive Mode you can select “**Add to study set”** (this is an awful name and can be changed) where you can add the text selected as a note/flash card to a study set that can be viewed in the “**Learn”** section. When you click “**Add to study set”** there will be a dropdown with all of the study sets you have created and the option to create a new study set. When you click “**Create a new study** **set**,” a modal pops up where you can write the name of the study set, then the study set is saved with that text snip-bit being the only thing in the study set.   
* Within the “**Learn**” section, users can review flashcards as they would in a typical flashcard application (Quizlet/Anki)


Non-Essential (Nice-to-Have)

* Avatars to represent the different media sources (NYT/WSJ, etc.) to tap on to view recent articles just from that source  
* Articles that can be scraped when you click on the article in feed, the article will open up directly in app  
* An AI tag that tags any articles in “**My Articles**” with topics, that can then be filtered to display  
* Within the “**Learn**” section, there will be an option for interactive learning.   
  * An AI will generate multiple-choice questions based on existing flashcards and/or recent articles and the user will have the chance to apply the skills they have learned.  
  * An AI will generate/you can build a mind map of a given study set to see how certain ideas/terms connected to each other.  
* In the Reading Mode of an article you can have an option to listen to the article   
* This is not a fleshed out thought: You should be able to export the material from the learn tab into a .docx/.txt/whatever to be able to import into Notebook LM (I love Notebook LM)  
* Ability for users to customize the system prompt that precedes the highlighted terms in the **AI Explain** feature.

Out of Scope (Won't Have)

* 

#### Non-Functional Requirements

Performance

* fast

Security

* \#no data leaks

Privacy

* I want all the data

Usability

* straightforward

#### Technology Stack

* Implement the application as a Progressive Web Application (PWA)  
  * Use the “Add to Home Screen” feature to make the webpage *feel* like a real app  
* Access to FSRS on GitHub: open-spaced-repetition/fsrs4anki  
* React, HTML, JS, CSS, shadcn  
* Supabase backend  
* Hosted github  
* Gemini flash lite and claude apis for chat component

## Product Roadmap

#### Iteration 1

Dates: TBD
Goal: Prove the ingestion pipeline end-to-end — discover a headline in the app, open it in Safari, push it back via the iOS Shortcut, and read it in the app.
Full plan: [docs/iteration-1-plan.md](./iteration-1-plan.md)

Must-Have Features:

* Name-based login, scoped per user
* Installable PWA shell with What's New / My Articles / Learn tabs
* What's New feed aggregating AP, Reuters, NPR, and BBC RSS
* Article ingestion endpoint + the iOS Shortcut that feeds it
* My Articles collection view, newest first
* Reading Mode (plain reading, no interactivity yet)

Nice-to-Have Features:

* Seed script for sample articles
* Saved-state marker on feed items already ingested

#### Iteration 2

Dates: TBD
Goal: Turn the reader into the product — interactive highlighting, AI explanation, and an FSRS-backed Learn tab.
Full plan: [docs/iteration-2-plan.md](./iteration-2-plan.md)

Must-Have Features:

* Interactive Mode: freeze + drag-to-highlight with an action bar
* AI Explain on a selection
* AI Chat scoped to a selection
* Double-tap Define, with every defined word saved to the Word Bank
* Add to Study Set (existing or newly created set)
* Learn: FSRS flashcard review
* Custom tags and filtering by tag, source, or journalist

Nice-to-Have Features:

* Promote a Word Bank entry into a study set card
* Per-set due counts in the Learn tab

#### Iteration 3

Dates:   
Goal:  
Must-Have Features:

* 

Nice-to-Have Features:

*  

#### Iteration 4

Dates:   
Goal:  
Must-Have Features:

* 

Nice-to-Have Features:

*  

