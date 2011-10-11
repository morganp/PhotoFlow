 #
 # PhotoFlow, A small Ruby Shoes Application for helping with a photography workflow
 # Copyright (C) 2009  Morgan Prior
 # 
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 # 
 # Contact morgan@amaras-tech.co.uk
 # http://amaras-tech.co.uk
 #
 #
 
require 'yaml'
require 'FileUtils'

class PhotoFlow < Shoes
   url '/',      :index
   url '/pref',  :pref
   url '/about', :about
   
   $configFile = ".photoflow" + File::SEPARATOR + "config.yml"
   
   
   def sensible_sort(unsorted)
     return  unsorted.sort_by {|k| k.to_s.split(/((?:(?:^|\s)[-+])?(?:\.\d+|\d+(?:\.\d+?(?:[eE]\d+)?(?:$|(?![eE\.])))?))/ms).map{|v| Float(v) rescue v.downcase}}
   end

 
   #Function to save Config file
   def saveConfig(configFile, config)
      #For Shoes compatability change to a known directory
      Dir.chdir(ENV['HOME'])
      #Test if exists
      if !(File.exist?(".photoflow"))
         FileUtils.mkdir_p (".photoflow")
      end
      open(configFile, 'w') {|f| YAML.dump(config, f)}
   end
    
   #Function to Load Settings
   def loadConfig(configFile)
      #For Shoes compatability change to a known directory
      Dir.chdir(ENV['HOME'])
      config = {}
      #f = open("|ls " + configFile)
      #foo = f.read()

      #@message.text = foo
      
      #do this to set parameters that might be missing from the yaml file
      config[:raw_conf_folder_loc]      = ""
      config[:drv_conf_folder_loc]      = ""
      config[:template_file_loc]        = ""
      config[:template_include_folder]  = false
      config[:launch_photo_transf]      = ""
      config[:launch_photo_editor]      = ""
      config[:append_template]          = false
      if File.exist?(configFile)
         config.update(open(configFile) {|f| YAML.load(f) })
      end
      return config
   end

   def about
      @app = app
      topMenu(0)
      stack  :margin => 10 do
         para "This application is designed to help simplify the photographic " +
               "workflow which was introduced by: \n", link("Pete Krogh", :click=>"http://www.peterkrogh.com/" ),
               " in ", link("The DAM book", :click => "http://www.thedambook.com/" ), "   ",
               link("(amazon link)", :click=>"http://www.amazon.co.uk/dp/0596100183?tag=morgue-21&camp=2902&creative=19466&linkCode=as4&creativeASIN=0596100183&adid=14PNCBSDACJ8R0Z6DCDA&") 
         
         para "Once the RAW and DRV folder are defined the 'Create Shoot Folder' button " + 
               "will create a new folder, prefixed with a 4 digit incrementing number " +
               "and the defined shoot name, ie 0001-test in both the RAW and DRV folders"
               
         para "If the template folder is defined, a copy of it will be made in the RAW/xxxx-shoot folders"
         
      caption "Acknowledgements"
 inscription  link("lazyjames", :click=>"http://www.lazyjames.co.uk"), " for his ruby tips \n",
               link("piers", :click=>"http://www.bofh.org.uk/"), " for the ruby ", 
               link("natural sorting", :click=>"http://www.bofh.org.uk/2007/12/16/comprehensible-sorting-in-ruby"), 
               " regular expression \n",
               link("_why", :click=>"http://whytheluckystiff.net/"), " for developing ", link("shoes", :click=>"http://shoooes.net") 
         
      caption "PhotoFlow  Copyright (C) 2009  Morgan Prior" 
  inscription "This program comes with ABSOLUTELY NO WARRANTY;"
      end
   end
   
   
   def index
      @app = app
      topMenu(1)
      
      @config = loadConfig($configFile)

      
      @app.stack :margin => 10 do
         #@message = caption("test")
         #@message.text = "testing"
         @message        = caption   "Enter Shoot name, then press Create " 
         @shoot_name     = edit_line "shoot_name", :width => 400 
         @create_shoot   = button    "Create Shoot Folder"

         @launch_copy    = button "Launch Photo Transfer"
         @launch_develop = button "Launch Photo Editor"

        #para "RAW Location"
        #if @config[:raw_conf_folder_loc].to_s.empty? 
        #   inscription ("not defined")
        #else
        #   inscription (@config[:raw_conf_folder_loc])
        #end
        
        #para "DRV Location"
        #if @config[:drv_conf_folder_loc].to_s.empty? 
        #   inscription ("not defined")
        #else
        #   inscription (@config[:drv_conf_folder_loc])
        #end
        
        #para "Template Location"
        #if @config[:template_file_loc].to_s.empty? 
        #   inscription ("not defined")
        #else
        #   inscription (@config[:template_file_loc])
        #end

        
      end
      
       @create_shoot.click {
          @folderlist = Dir.entries(@config[:raw_conf_folder_loc]) ##- ['.', '..']
          @folderlist = @folderlist.find_all{|item| item =~ /(\d+)/ }
          sensible_sort(@folderlist).last =~ /(\d+)/
      
          @highest = ($1.to_i + 1).to_s
          #Zero pad Shoot number
          while (@highest.length < 4) do
            @highest = "0" +@highest
          end
          @new_dir = @highest + "-" + @shoot_name.text
          
          # Create matching hierarchies
          FileUtils.mkdir_p( File.join( @config[:raw_conf_folder_loc], @new_dir ) )
          FileUtils.mkdir_p( File.join( @config[:drv_conf_folder_loc], @new_dir ) )
         
         @message.text =  @new_dir
         
         #This crashes when the file does not exist TODO add extra if exists checks
         ##Modify this to copy file or folder based on new pref
          if (! @config[:template_file_loc].to_s.empty?) 
             item_to_copy = ""
             if ( @config[:template_include_folder] == true )
             # take all but text after last File::SEPARATOR
                lastdir    = (@config[:template_file_loc].to_s).rindex(File::SEPARATOR)
                item_to_copy = (@config[:template_file_loc].to_s)[0,lastdir]
             else
                item_to_copy = @config[:template_file_loc]
             end
             
            if File.exist?( item_to_copy )
              new_location = File.join(@config[:raw_conf_folder_loc], @new_dir)
              FileUtils.cp_r(item_to_copy, new_location)
            else
              @message.text =  "Template Library Failed to Copy"
            end
             
          end
          
       } 
       
       @launch_copy.click {
          if (RUBY_PLATFORM.include? ("darwin")) 
             runcmd = "open \"" + (@config[:launch_photo_transf]).to_s + "\""
             system(runcmd)
          else
             system(@config[:launch_photo_transf].to_s)
          end
       }
       
       @launch_develop.click {
          runcmd = String.new
          if (RUBY_PLATFORM.include? ("darwin")) 
              runcmd = "open \"" + (@config[:launch_photo_editor]).to_s + "\""
          else
             runcmd = @config[:launch_photo_editor].to_s
          end
          
          if @config[:append_template]
             reversed = @config[:template_file_loc].to_s.reverse
             pos1 = (reversed).index(File::SEPARATOR)
             
             if @config[:template_include_folder]
                pos1 = (reversed).index(File::SEPARATOR, pos1+1) 
             end
            
            open_template = reversed[0,pos1].reverse

             dirposition    = " \"" + File.join( @config[:raw_conf_folder_loc], @new_dir, open_template) + "\""
             runcmd = runcmd + dirposition
          end
          system(runcmd)
       }

   end ##index
   
   
   
   def pref
      @app = app
      topMenu(2)
      @config = loadConfig($configFile)
      stack  :margin => 10  do
        
        para("Top Level RAW ")
        @raw_folder      = edit_line(:width => 400) do |e|
            @config[:raw_conf_folder_loc] = e.text
        end
        @raw_folder.text = @config[:raw_conf_folder_loc]
        @new_raw         = button "Select RAW Path" 
         
         
        para("Top Level DRV ")
        @drv_folder      = edit_line(:width => 400) do |e|
            @config[:drv_conf_folder_loc] = e.text
        end
        @drv_folder.text = @config[:drv_conf_folder_loc]
        @new_drv         = button "Select DRV Path"
         
         
        para("Copy Template file into Raw Folder ")
        @template_file_loc      = edit_line(:width => 400) do |e|
            @config[:template_file_loc] = e.text
        end
        @template_file_loc.text = @config[:template_file_loc]
        @new_template         = button "Select Template Path"
        
        flow {
           @template_include_folder         = check
           @template_include_folder.checked = @config[:template_include_folder]
           para ("Copy folder containing template")
        }
        
        
        para("Photo Transfer")
        @launch_photo_transf      = edit_line(:width => 400) do |e|
            @config[:launch_photo_transf] = e.text
        end
        @launch_photo_transf.text = @config[:launch_photo_transf]
        @new_photo_transfer         = button "Select Photo Transfer"
        
        
        
        para("Photo Editor")
        @launch_photo_editor      = edit_line(:width => 400) do |e|
            @config[:launch_photo_editor] = e.text
        end
        @launch_photo_editor.text = @config[:launch_photo_editor]
        @new_photo_editor         = button "Select Photo Editor"
        
        flow {
           @append_template       = check
           @append_template.checked = @config[:append_template]
           para ("Append template to editor launch")
        }
        
        @save                 = button "Save Config"
      end
      
      @new_raw.click {
         @config[:raw_conf_folder_loc] = ask_open_folder
         @raw_folder.text              = @config[:raw_conf_folder_loc]
      }
   
      @new_drv.click {
         @config[:drv_conf_folder_loc] = ask_open_folder
         @drv_folder.text              = @config[:drv_conf_folder_loc]
      }
   
      @new_template.click {
         @config[:template_file_loc]   = ask_open_file
         @template_file_loc.text       = @config[:template_file_loc]
      }
      
      @template_include_folder.click {
         @config[:template_include_folder] = @template_include_folder.checked?
      }

      
      @new_photo_transfer.click {
         @config[:launch_photo_transf]    = ask_open_file
         @launch_photo_transf.text        = @config[:launch_photo_transf]
      }
      
      @new_photo_editor.click {
         @config[:launch_photo_editor]    = ask_open_file
         @launch_photo_editor.text        = @config[:launch_photo_editor]
      }
      
      @append_template.click {
         @config[:append_template]        = @append_template.checked?
      }
      
      @save.click {
         saveConfig($configFile, @config)  
      }
   
   end 
   
   def topMenu (tabNo)
      
      #Change settings here as required
      inactiveTabColor = "#B0B0B0"
      mainBodyColor    = "#D0D0D0"
      topColor         = "#E0E0E0"
      no_of_tabs       = 3
      tab_width        = 60
      tab_height       = 30
      tab_overlay      = 8
      ##################################
      #Order and links of tabs
      names = Array.new
      names[0] = {:name=>"about", :link=>"/about"}
      names[1] = {:name=>"main",  :link=>"/"}
      names[2] = {:name=>"prefs", :link=>"/pref"}
      ##################################
      
      background mainBodyColor
      #Make background for tabs a lighter colour
      background topColor, :height=> (tab_height-tab_overlay)

      #Add black line under tabs
      stroke black
      @app.line(0,(tab_height-tab_overlay),@app.width(),(tab_height-tab_overlay))
      
      #Do not alter calculations for tabs
      tabsSpace = @app.width() / (no_of_tabs + 1)
      currentTabCentre = tabsSpace
      indentamount = Array.new
      #Loop and draw tabs
      (0...no_of_tabs).each do |i|
         #Deactive tabs different colour
         if i == tabNo
            fill mainBodyColor
         else 
            fill inactiveTabColor
         end
         #Calculate position and size of tabs
         currentTabStart = currentTabCentre - (tab_width/2)
         indentamount[i]  = currentTabStart
         @app.rect(currentTabStart,2,tab_width, (tab_height-2+5), :curve=>12)
         currentTabCentre  = currentTabCentre + tabsSpace
         
         #Add black line to the bottom of deactivated tabs
         if i != tabNo
            @app.line(currentTabStart,(tab_height-8),(currentTabStart+tab_width),(tab_height-8))
         end
         
         #Set Tab Text Here
         @app.flow :left => indentamount[i], :width => tab_width do 
           para link(names[i][:name], :click=>names[i][:link],  :stroke => black, :underline => "none"), :align => "center"
         end
         
      end
      
      #Cover up the bottom of the tabs so they have square bottom
      fill   mainBodyColor
      stroke mainBodyColor
      @app.rect(0, (tab_height-tab_overlay+1), @app.width(), (tab_overlay+4))
   
      #Put pen back to black
      stroke black
   end

   
   
end
Shoes.app :title => "PhotoFlow",  :width=>450, :height=>600
