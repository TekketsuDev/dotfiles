# saving packages list to a file
echo "dependecy1 dependency2 dependency3" > ~/QTproject.pkgs

# installing packages "tagged" as QTproject
cat ~/QTproject.pkgs | pacman -Syu -

# removing packages "tagged" as QTproject and their dependencies
cat ~/QTproject.pkgs | pacman -Rns -
