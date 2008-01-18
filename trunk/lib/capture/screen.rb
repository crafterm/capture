require 'osx/cocoa'
require 'capture/extensions'

module Capture
  class Screen

    def self.capture
      fade do
        screenshot = OSX::CGWindowListCreateImage(OSX::CGRectInfinite, OSX::KCGWindowListOptionOnScreenOnly, OSX::KCGNullWindowID, OSX::KCGWindowImageDefault)
        OSX::CIImage.imageWithCGImage(screenshot)
      end
    end

    private

      def self.fade
        err, token = OSX::CGAcquireDisplayFadeReservation(OSX::KCGMaxDisplayReservationInterval)

        if err == OSX::KCGErrorSuccess
          begin
            OSX::CGDisplayFade(token, 0.3, OSX::KCGDisplayBlendNormal, OSX::KCGDisplayBlendSolidColor, 0, 0, 0, true)

            snap(token)

            return yield if block_given?
          ensure
            OSX::CGDisplayFade(token, 0.3, OSX::KCGDisplayBlendSolidColor, OSX::KCGDisplayBlendNormal, 0, 0, 0, false)
            OSX::CGReleaseDisplayFadeReservation(token)
          end
        end
      end

      def self.snap(token)
        display = OSX::CGMainDisplayID()

        if OSX::CGDisplayCapture(display) == OSX::KCGErrorSuccess
          begin
            ctx = OSX::CGDisplayGetDrawingContext(display)
            if ctx
              pic = OSX::CIImage.from(File.dirname(__FILE__) + '/nikon.jpg')

              OSX::CGDisplayFade(token, 0.0, OSX::KCGDisplayBlendSolidColor, OSX::KCGDisplayBlendNormal, 0, 0, 0, true)

              # calculate middle of the screen for the images location
              display_width, display_height = OSX::CGDisplayPixelsWide(display), OSX::CGDisplayPixelsHigh(display)
              pic_width, pic_height = pic.extent.size.width, pic.extent.size.height
              position_x, position_y = (display_width - pic_width) / 2.0, (display_height - pic_height) / 2.0

              OSX::CGContextDrawImage(ctx, OSX::NSRectFromString("#{position_x} #{position_y} #{pic_width} #{pic_height}"), pic.cgimage)

              sleep(0.7)

              OSX::CGDisplayFade(token, 0.0, OSX::KCGDisplayBlendNormal, OSX::KCGDisplayBlendSolidColor, 0, 0, 0, true)
            end
          ensure
            OSX::CGDisplayRelease(display)
          end
        end
      end
  end
end
