# Extra recipe jailbreak

Apart from the default Yalu logo, your can also pick your favourite logo:

![logo0](https://github.com/samcsli/extra_recipe/blob/master/CollegeHumor.png?raw=true)by [CollegeHumor](https://www.youtube.com/watch?v=PWiT6VbVpjg)

![logo1](https://github.com/samcsli/extra_recipe/blob/master/mod-appico.png?raw=true)by wind3v


Credits:

* Ian Beer for the amazingly simple, yet awesome, kernel exploit
* @qwertyoruiop for the amazingly complicated, yet effective, memprot bypass
* @xerub ~ rewrite (extra_recipe)

Please use the "Issues" tab for **code related** issues only. If you need support please search on [/r/jailbreak](https://reddit.com/r/jailbreak) before posting a question there.

## Supported Devices and iOS versions

| Device | Version |
|---------|----------|
| iPhone 7  | iOS 10.0.0 -> iOS 10.1.1 |

**Note, the iPhone 7 is only supported till iOS 10.1.1**
If you are already on iOS 10.2 with an iPhone 7, **stay there**. The actual exploit behind this still works, but the KPP bypass does not.

## Compiling:

1. `git clone` the repo.
2. Open the repo in Xcode
3. Change the bundle ID, as shown [here](https://www.reddit.com/r/sideloaded/wiki/how-to-sideload#wiki_changing_the_bundle_identifier_and_team)
4. Include the IOKit headers, and add them to your search path.
5. Run the project.

## Warnings

This jailbreak is a work in progress. Some things do not work, but most things do.

Do not install things that are untested.

**OpenSSH and other unsupported and untested software will probably throw your device into a bootloop or do other bad things.** Do not open an issue complaining that your device has been bootlooped because you installed other software. You have been warned.

## Installing

> DO NOT DOWNLOAD THIS SOFTWARE FROM OTHER SOURCES OTHER THAN THESE LINKS UNDER ANY CIRCUMSTANCE. IT IS VERY EASY TO BACKDOOR THIS SORT OF SOFTWARE TO CONTAIN MALWARE. PLEASE BE EXTREMELY CAREFUL. THESE MIRRORS ARE TRUSTED, BUT STILL CHECK THE SHA1.

* Download the pre-compiled version from the table below.
* [Check the SHA1 hash](http://onlinemd5.com) of the downloaded file (optional but recommended).
* Install using [Cydia Impactor](http://www.cydiaimpactor.com/).
* Open the application and follow instructions.


| Version | Download | SHA1 |
|---------|----------|------|
| Beta 3  | [Link](https://yalu.qwertyoruiop.com/extra_recipe+yaluX%20beta3.ipa) | 020C06D21354C9CE138C9413BF6FECF1621F7AF3  |


## Contributing

Create a fork of the repository, make your changes and then create a pull request.
Please be sure to check if the pull request has been made before, before creating a new one. Note, any pull requests adding IOKit headers will be closed. Please respect copyright laws, and do not distribute / download IOKit headers from unofficial sources: they are bundled legally with macOS SDK

