

.PHONY:
main:
	gcc -g -fno-pie -no-pie -c sum.c
	gcc -g -fno-pie -no-pie -c main.c
	gcc -g -fno-pie -no-pie -o main main.o sum.o

.PHONY:
main.2:
	gcc -g -fno-pie -no-pie -c sum.c
	gcc -g -fno-pie -no-pie -c main.2.c
	gcc -g -fno-pie -no-pie -o main.2 main.2.o sum.o

.PHONY:
clean:
	rm sum.o
	rm main.o
	rm main.2.o
	rm main
	rm main.2
